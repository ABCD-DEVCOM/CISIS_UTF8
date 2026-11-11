# XCore Engine (CISIS) — limits and sizes of every variant

This document answers one question: **what are the exact limits of each binary you can build with
`build_linux.sh` / `build_all.sh` / `build_windows_all_bcc55.bat`?**

Every number is tagged:

* **measured** — obtained by running the real binary (32- and 64-bit Linux builds, UTF-8), with the probe
  scripts described in the last section;
* **derived** — computed from the source (`cisis.h`, `cidbx.c`, `cirec.c`, `ciupd.c`) and **not** exercised, or
  only partially exercised, because the test would need tens of gigabytes;
* **not measured** — we did not look at it.

Where a measured number differs from what the banner or the source suggests, it is called out in
[Surprises](#surprises-found-while-measuring).

---

## 1. Reading the banner

```
XCore Engine v0.1.0 / G / PC / 512G / W / F / L4 / M / 1048576 / 16 / 60 / I / 64bits / UTF-8
                      │   │    │     │   │   │    │   │         │    │    │    │        └ UTF8=1 build
                      │   │    │     │   │   │    │   │         │    │    │    └ SIXTY_FOUR: 64-bit executable
                      │   │    │     │   │   │    │   │         │    │    └ I  = inverted-file update (IFUPDATE)
                      │   │    │     │   │   │    │   │         │    └ LE2 = longest index key, in bytes
                      │   │    │     │   │   │    │   │         └ LE1 = key length kept in the upper B-tree level
                      │   │    │     │   │   │    │   └ MAXMFRL = longest record, in bytes
                      │   │    │     │   │   │    └ M  = MULTI (multi-user / locking code)
                      │   │    │     │   │   └ L  = LIND inverted file   (L4 = LIND4: 4-byte MFN in postings)
                      │   │    │     │   └ F  = CIFFI: long records (24-byte leader, 12-byte directory entry)
                      │   │    │     └ W  = CIWTF (word-type functions compiled in)
                      │   │    └ "512G" is printed whenever _LARGEFILE64_SOURCE is on. It is a hard-coded
                      │   │      string: it does NOT report the real .mst capacity (see section 3.5)
                      │   └ PC = packed, little-endian file layout (the BIREME "PC" format; also used on Linux)
                      └ G  = compiled with gcc
```

`1660` in a variant name means LE1/LE2 = 16/60 (instead of the original 10/30).

---

## 2. Summary table

| variant | banner (middle part) | max record | longest single field | key (LE2) | max MFN | .mst capacity | inverted file | Windows |
|---|---|---:|---:|---:|---:|---:|---|:--:|
| `isis`      | `M/32767/10/30`           | 32,767    | 32,733    | 30  | 16,777,215     | 512 MB | classic (`.l01 .l02 .ifp`) | yes |
| `isisG`     | `512G/M/32767/10/30`      | 32,767    | 32,733    | 30  | 16,777,215     | 512 MB | classic | no |
| `isis1660`  | `M/32767/16/60`           | 32,767    | 32,733    | 60  | 16,777,215     | 512 MB | classic | yes |
| `lind`      | `L/M/32767/16/60`         | 32,767    | 32,733    | 60  | 16,777,215     | 512 MB | LIND (`.ly1 .ly2 .iyp`) | yes |
| `lindG4`    | `512G/L4/M/32767/16/60`   | 32,767    | 32,671    | 60  | 2,147,483,521* | 32 GB  | LIND, 4-byte MFN | no |
| `lind512`   | `L/M/32767/16/512`        | 32,767    | 32,733    | 512 | 16,777,215     | 512 MB | LIND | yes |
| `lind512G4` | `512G/L4/M/32767/16/512`  | 32,767    | 32,671    | 512 | 2,147,483,521* | 32 GB  | LIND, 4-byte MFN | no |
| `ffi`       | `F/L/M/1048576/16/60`     | 1,048,576 | 1,048,527 | 60  | 16,777,215     | 8 GB   | LIND | yes |
| `ffiG4`     | `512G/F/L4/M/1048576/16/60` | 1,048,576 | 1,048,527 | 60 | 2,147,483,521* | 32 GB | LIND, 4-byte MFN | no |
| `ffiG4_4`   | `512G/F/L4/M/4194304/16/60` | 4,194,304 | 4,194,255 | 60 | 2,147,483,521* | 32 GB | LIND, 4-byte MFN | no |
| `ffi512`    | `F/L/M/1048576/16/512`    | 1,048,576 | 1,048,527 | 512 | 16,777,215     | 8 GB   | LIND | yes |
| `ffi512G4`  | `512G/F/L4/M/1048576/16/512` | 1,048,576 | 1,048,527 | 512 | 2,147,483,521* | 32 GB | LIND, 4-byte MFN | no |
| `ffi1660`   | `F/M/1048576/16/60`       | 1,048,576 | 1,048,527 | 60  | 16,777,215     | 8 GB   | classic | yes |
| `bigisis`   | `512G/F/M/1048576/16/256` | 1,048,576 | 1,048,527 | 256 | 16,777,215     | 32 GB  | classic | no |

All lengths are in bytes. `*` = nominal limit is 2,147,483,647, the highest MFN that really works is 2,147,483,521
(see [Surprises](#surprises-found-while-measuring)). `bigisis` is a large-file build but keeps 3-byte MFNs, so its MFN limit is the small one. "Windows" = can be built with Borland C++ 5.5 by
`build_windows_all_bcc55.bat` (it has no large-file seek: the G/G4 variants and `bigisis` are Linux-only).

How each column was obtained:

| column | status |
|---|---|
| max record | **measured** (value of `MFRL` in the banner = compile-time `MAXMFRL`; records above it are refused) |
| longest single field | **measured** by bisection: one field of N bytes created with `proc=` and read back with `size()` |
| key (LE2) | **measured** on all 14 variants, 32- and 64-bit: a 1000-character term is stored cut to exactly this length |
| max MFN | **measured** on every variant: 16,777,215 OK and 16,777,216 = `fatal: recupdat/mfn` for the 3-byte-MFN ones; all five `L4` variants accepted 16,777,216, and `lindG4`/`ffiG4` were pushed to 2,147,483,521 |
| .mst capacity | formula **derived** (512 MB × 2^mstxl); **measured**: `isis` stops at 512 MB, 64-bit `ffi1660` passed 2 GB, 64-bit `ffiG4` passed 1 GB, 32-bit `ffiG4` passed 4 GB; 32-bit `ffi1660` stops at 2 GiB (file-system limit of a 32-bit `off_t`) |

### What to pick

* Default for ABCD (`wxis`): **`ffi1660`** — records up to 1 MiB, keys up to 60, 16.7 million records, classic index. On a 32-bit
  `off_t` system the master stops at 2 GiB.
* Records longer than 32 KB: any `F` variant (`ffi*`, `bigisis`).
* More than 16.7 million records, or masters over 2 GiB on a 32-bit system: the `G4` variants (`lindG4 lind512G4 ffiG4 ffiG4_4 ffi512G4`); Linux only. Note that `bigisis` has 3-byte MFNs.
* Index keys longer than 60 characters: `*512` variants (512) or `bigisis` (256).
* Records longer than 1 MiB: `ffiG4_4` (4 MiB), or add a row with another `MAXMFRL` to `build_linux.sh` (the `ffiG4_4` row is the template).
* Do not mix variants on one database: section 4.

---

## 3. Details, limit by limit

### 3.1 Record length and field size

* The ceiling is the compile-time constant `MAXMFRL` (shown in the banner): **32,767** for the original layout,
  **1,048,576** for FFI builds (`F`), and whatever `-DMAXMFRL=` says (`ffiG4_4`: 4,194,304).
* A record is `leader + directory + data`. With one field the largest data that fits is
  **measured**: `MFRL − 34` (classic), `MFRL − 49` (FFI), and `lindG4`/`lind512G4` fit 62 bytes less than the other
  classic variants (32,671 instead of 32,733; the reason was not investigated).
* Classic records use a 2-byte length, FFI records a 4-byte length (**derived**: `FFI` is `UWORD` or `unsigned int` in `cisis.h`), so **FFI is the only way past 32,767 bytes**.
* Run-time option `mfrl=N` (mx) / `maxmfrl=` (cipar) changes the limit for one run. It is accepted up to the compile-time
  `MAXMFRL` (**measured**: `mfrl=65535` and `mfrl=262144` work in the 1 MiB builds, `mfrl=2000000` works in `ffiG4_4`).
  **Above the compile-time value there is no error message: the record is written and read back wrong** (the size
  comes back 1 to 7 bytes off and bytes at the end are lost). Never use it that way.
* `seq=` (text import) is more restrictive than the record: a field longer than about `MAXMFRL − 4099` bytes
  is cut **silently** (**measured** earlier on `ffi1660`). Create big fields with `proc=` or the API.

### 3.2 Fields per record and tags

| | classic (`MFRL` 32,767) | FFI (`MFRL` 1,048,576) |
|---|---:|---:|
| bytes per field (directory + 1 data byte) | 7 | 13 |
| fields of 1 byte in one record | 4,678 OK / 4,700 fails (**measured**; `lindG4`, `lind512G4`: 4,669 OK) | 80,650 OK / 80,700 fails (**measured**) |
| theoretical maximum (record length − leader) ÷ bytes per field | 4,678 | 80,657 |

So the number of fields is not an independent limit: it is the record length divided by the directory entry.
Two quirks of the format language (`mx pft=`), not of the file: `nocc()` and the repeating group `(v1/)` stop at
**9,999** occurrences (**measured**: a record with 12,000 occurrences of v1 prints 9,999 lines, but `v1[10000]` and
`v1[12000]` still return data).

Tag numbers: **1 to 32,767** in every variant (**measured**: 32,767 stored and read, 32,768 refused).

### 3.3 Index keys (LE1 / LE2)

* `LE2` is the longest key stored in the index: **30** (`isis`, `isisG`), **60** (`isis1660 lind lindG4 ffi ffiG4 ffiG4_4
  ffi1660`), **256** (`bigisis`), **512** (`lind512 lind512G4 ffi512 ffi512G4`). **Measured** on all 14 variants, 32- and
  64-bit, by indexing a 1000-character term and reading `mx dict=db "pft=v1^s"`: the dictionary record is
  `key^l2^s<stored length>^t1^k1`, and `^s` is the length that was really stored. (Measuring the printed line instead
  gives wrong numbers because `mx` wraps its output.)
* Longer terms are truncated, not rejected: two words that share the first `LE2` bytes become one index entry.
* `LE1` (10 or 16) is internal to the B-tree (key prefix kept in the upper level); it is not a limit you can hit.
* Changing `LE2` changes the node sizes of the index files, so an index built with one `LE2` cannot be read by
  a binary with another (see section 4).

### 3.4 Record numbers (MFN)

| | highest MFN | what happens beyond |
|---|---:|---|
| every variant without `L4`: `isis isisG isis1660 lind lind512 ffi ffi512 ffi1660` (`MAXUPDMFN` = 0xFFFFFF) | **16,777,215** (0xFFFFFF) | `fatal: recupdat/mfn` (**measured** on all of them) |
| `lindG4 lind512G4 ffiG4 ffiG4_4 ffi512G4` (`LIND4`, 4-byte MFN) | nominal 2,147,483,647; **real 2,147,483,521** | `fatal: recxref/lseek` (**measured**, see Surprises) |
| `bigisis` (large-file, but 3-byte MFN) | **16,777,215** | `fatal: recupdat/mfn` (**measured**) |

How the test was done: create a one-record database, set `nxtmfn` in the control record of the `.mst` (offset 4) to the
value under test, give the `.xrf` a valid last block (negative block number header + zero pointers; the file
becomes sparse: apparent size 8.6 GB for MFN 2.1 billion, almost nothing really allocated) and append two records.

The `.xrf` file needs 4 bytes per MFN plus a 4-byte header per 127 MFNs: about **64 MB** for 16 million records
and about **8.6 GB** for 2.1 billion.

### 3.5 Size of the master file (.mst)

Record addresses are stored in 32 bits as *block number* × *offset inside the block*. The `mstxl` parameter stretches
that address: capacity = **512 MB × 2^mstxl** (**derived** from `cirec.c`, `recxref`). The default `mstxl` is chosen in
`cidbx.c`:

| build | `mstxl` | capacity | records start at multiples of |
|---|---:|---:|---:|
| `LIND4` (or `SUPERISIS`) and large-file: `lindG4 lind512G4 ffiG4 ffiG4_4 ffi512G4 bigisis` | 6 | **32 GB** | 64 bytes |
| `CIFFI` otherwise: `ffi ffi512 ffi1660` | 4 | **8 GB** | 16 bytes |
| everything else: `isis isisG isis1660 lind lind512` | 0 | **512 MB** | 1 byte |

* **Measured:** `isis` fails at 512 MB with `fatal: recxref/comp+MSNVSPLT`; `ffi1660` (8 GB by the table) held 2 GB
  without error; `ffiG4` (32 GB) held 1 GB without error. Nobody has filled 8 or 32 GB.
* The value used is stored in the control record (`mftype / 256`), so **an existing database keeps the `mstxl` it was
  created with**, whatever the binary's default is. A cipar entry `mstxl=` overrides the default for new databases (**derived** from `cisisx.c`).
* The banner's `512G` has nothing to do with this: it is printed for any large-file build, even `isisG` whose real limit is 512 **MB**.
* The file system matters too: a build with a 32-bit `off_t` (every non-G build on a 32-bit system, and every
  Borland C++ 5.5 build, **derived** for the latter) cannot seek beyond 2 GB, so the `mstxl` capacity is academic there.
  **Measured:** 32-bit `ffi1660` stops when the file reaches 2,147,483,647 bytes (`fatal: recwmast/write/rec`); 32-bit `ffiG4`
  (large-file) held a 4.1 GB master and read back its last record. The Windows BCC 5.5 builds behave like 32-bit `ffi1660`.

### 3.6 Inverted file

| family | files | postings | notes |
|---|---|---|---|
| classic | `.cnt .n01 .n02 .l01 .l02 .ifp` | 3-byte MFN, block-chained | `isis isisG isis1660 ffi1660 bigisis` |
| LIND | `.cnt .n01 .n02 .ly1 .ly2 .iyp` | bit string / MFN list / counted list, chosen per term | `lind* ffi*`; `L4` = 4-byte MFN |

* Key length: section 3.3. A term can occur in at most `MAXUPDMFN` records (section 3.4).
* Maximum size of `.ifp` / `.iyp`, number of postings per term, occurrence and word counters inside a posting:
  **not measured**.

---

## 4. Which binary can open which database

### 4.1 Rules (measured)

1. **Master file (`.mst` + `.xrf`)**: two families, split by the `F` flag (`CIFFI`).
   Every non-`F` variant reads the masters of every other non-`F` variant, and every `F` variant reads every other `F`
   variant (including `bigisis`), in 32- and 64-bit builds, with the same bytes. Across the two families the binary
   stops at the first record with `fatal: recread/check/base` (the leader is 18 bytes in one family and 22 in the other).
2. **Inverted file**: the index only works with a binary of the **same index family**, which is narrower than the master
   family (it depends on `LE1/LE2`, classic or LIND, 3- or 4-byte MFN). Results of the cross-reading matrix are in 4.2.
3. Only reading was tested. **Updating** a database (`fullinv`, `append=`, writing records) with a binary of another
   family was not tested and should be avoided.
4. Behavior in the cross-family cases falls into three groups: a clear `fatal:` (the common case), a dictionary that
   reads fine but a search that stops (`D` only), and — rarely — **a silently wrong answer**. The silent ones are listed in 4.2.

### 4.2 Measured matrices

Database of **3,000 records** (one common term, one in half of the records, one in a single record, one in 300
consecutive records, 3,000 distinct terms, a 46-character term), so the index has several B-tree levels and
postings in the three LIND forms. Every variant creates the database; every variant reads it. Rows = the binary that
**wrote** the database, columns = the binary that **reads** it. Each cell has three letters:

* `M` master file read correctly · `D` dictionary (`mx dict=`) identical · `S` seven searches return the same hit counts
* `x` = the binary stopped with an error · `w` = it ran **without any error and printed something different** (wrong answer)

```
#1=isis #2=isisG #3=isis1660 #4=lind #5=lindG4 #6=lind512 #7=lind512G4 #8=ffi #9=ffiG4 #10=ffiG4_4 #11=ffi512 #12=ffi512G4 #13=ffi1660 #14=bigisis
```

**64-bit builds** (reader and writer both 64-bit):

```
writer \ reader  #1  #2  #3  #4  #5  #6  #7  #8  #9  #10 #11 #12 #13 #14
 1 isis       MDS MDS Mxx Mxx Mxx Mxx Mxx xxx xxx xxx xxx xxx xxx xxx
 2 isisG      MDS MDS Mxx Mxx Mxx Mxx Mxx xxx xxx xxx xxx xxx xxx xxx
 3 isis1660   Mxx Mxx MDS Mxx Mxx Mxx Mxx xxx xxx xxx xxx xxx xDx xxx
 4 lind       Mxx Mxx Mxx MDS Mxx Mxx Mxx xDx xxx xxx xxx xxx xxx xxx
 5 lindG4     Mxx Mxx Mxx Mwx MDS Mxx Mxx xwx xDx xDx xxx xxx xxx xxx
 6 lind512    Mxx Mxx Mxx Mxx Mxx MDS Mxx xxx xxx xxx xDx xxx xxx xxx
 7 lind512G4  Mxx Mxx Mxx Mxx Mxx Mwx MDS xxx xxx xxx xwx xDx xxx xxx
 8 ffi        xxx xxx xxx xDx xxx xxx xxx MDS Mxx Mxx Mxx Mxx Mxx Mxx
 9 ffiG4      xxx xxx xxx xwx xDx xxx xxx Mwx MDS MDS Mxx Mxx Mxx Mxx
10 ffiG4_4    xxx xxx xxx xwx xDx xxx xxx Mwx MDS MDS Mxx Mxx Mxx Mxx
11 ffi512     xxx xxx xxx xxx xxx xDx xxx Mxx Mxx Mxx MDS Mxx Mxx Mxx
12 ffi512G4   xxx xxx xxx xxx xxx xwx xDx Mxx Mxx Mxx Mwx MDS Mxx Mxx
13 ffi1660    xxx xxx xDx xxx xxx xxx xxx Mxx Mxx Mxx Mxx Mxx MDS Mxx
14 bigisis    xxx xxx xxx xxx xxx xxx xxx Mxx Mxx Mxx Mxx Mxx Mxx MDS
```

**32-bit builds**:

```
writer \ reader  #1  #2  #3  #4  #5  #6  #7  #8  #9  #10 #11 #12 #13 #14
 1 isis       MDS MDS Mxx Mxx Mxx Mxx Mxx xxx xxx xxx xxx xxx xxx xxx
 2 isisG      MDS MDS Mxx Mxx Mxx Mxx Mxx xxx xxx xxx xxx xxx xxx xxx
 3 isis1660   Mxx Mxx MDS Mxx Mxx Mxx Mxx xxx xxx xxx xxx xxx xDx xxx
 4 lind       Mxx Mxx Mxx MDS MDw Mxx Mxx xDx xDx xDx xxx xxx xxx xxx
 5 lindG4     Mxx Mxx Mxx MDS MDS Mxx Mxx xDx xDx xDx xxx xxx xxx xxx
 6 lind512    Mxx Mxx Mxx Mxx Mxx MDS MDw xxx xxx xxx xDx xDx xxx xxx
 7 lind512G4  Mxx Mxx Mxx Mxx Mxx MDS MDS xxx xxx xxx xDx xDx xxx xxx
 8 ffi        xxx xxx xxx xDx xDx xxx xxx MDS MDw MDw Mxx Mxx Mxx Mxx
 9 ffiG4      xxx xxx xxx xDx xDx xxx xxx MDS MDS MDS Mxx Mxx Mxx Mxx
10 ffiG4_4    xxx xxx xxx xDx xDx xxx xxx MDS MDS MDS Mxx Mxx Mxx Mxx
11 ffi512     xxx xxx xxx xxx xxx xDx xDx Mxx Mxx Mxx MDS MDw Mxx Mxx
12 ffi512G4   xxx xxx xxx xxx xxx xDx xDx Mxx Mxx Mxx MDS MDS Mxx Mxx
13 ffi1660    xxx xxx xDx xxx xxx xxx xxx Mxx Mxx Mxx Mxx Mxx MDS Mxx
14 bigisis    xxx xxx xxx xxx xxx xxx xxx Mxx Mxx Mxx Mxx Mxx Mxx MDS
```

Same variant, different word size (database written by one, read by the other), in the order #1…#14:

```
32-bit writer -> 64-bit reader: MDS MDS MDS MDS Mxx MDS Mxx MDS Mxx Mxx MDS Mxx MDS MDS
64-bit writer -> 32-bit reader: MDS MDS MDS MDS Mwx MDS Mwx MDS Mwx Mwx MDS Mwx MDS MDS
```

Reading the matrices:

* The block structure on the diagonal **is** the compatibility rule. Masters (`M`): two big blocks, non-`F` (#1–#7) and `F` (#8–#14).
  This holds even though the variants differ in `mstxl`, so the `mstxl` stored in the control record is honored on read.
* Indexes (`D`,`S`) are much narrower. In **64-bit** builds only `isis`≡`isisG` and `ffiG4`≡`ffiG4_4` (identical settings) share an index.
  In **32-bit** builds the pairs that differ only by the G4 flag also open each other's index (`lind`↔`lindG4`,
  `lind512`↔`lind512G4`, `ffi`↔`ffiG4`↔`ffiG4_4`, `ffi512`↔`ffi512G4`), but when the **non-G4** binary wrote the
  index and the **G4** one reads it, the searches are silently wrong (`MDw`).
* In 64-bit builds an index written by a G4 binary and opened by the matching non-G4 one prints a wrong dictionary without
  any message (`w` in the middle: `Mwx`, `xwx`).
* A database written by a 64-bit G4 binary and opened by the 32-bit one of the same name gives `Mwx` (silently wrong dictionary).
* The same matrix with a 5-record database shows `MDS` (everything fine) in the cases that are `MDw` above: **small
  test databases cannot detect these mismatches**; bigger ones with rare terms can.
* No cell produced `recxref/read`. With cross-variant reading the failure is always `recread/check/base` (master) or
  `noderead/read`, `leafread/read`, `trmread/punt`, `postread/read`, `*** wp=` and missing-file errors (index).

### 4.3 What this says about "making the binary smarter"

* The *master* side is already partly self-describing: `mstxl` is read from the control record (confirmed by the matrix: a master created with `mstxl` 6 is read correctly by binaries whose default is 4 or 0), and everything else
  that differs (leader/directory size, MFRL ceiling) differs between **two** families only. A binary compiled as FFI
  cannot read a classic leader and vice versa, because the structures are fixed at compile time (`DIRSTRU`, `LEADER`,
  `INFO`, `PMFNSIZ`…); trying one layout after the other at run time would require every one of those to become a
  run-time value. That is a refactor of the whole engine, not a retry loop.
* The cheapest way to get what you describe — "try another way until it works" — is a front-end that **looks at the
  files first** (control record `mftype`, leader of record 1, node sizes in the `.cnt`) and then starts the right
  executable. That needs no change to the engine itself. Nothing was implemented; this document gives the numbers a
  decision needs.

---

## 5. Surprises found while measuring

1. **`INFX` was `unsigned int` in 64-bit LIND builds without large-file support** (`cisis.h`, around line 771).
   The posting header stores a negative value to mean "bit string"; as unsigned it was never negative, so those
   builds crashed on LIND indexes: **measured**, the 64-bit `lind` built with the original `cisis.h` ends with a
   segmentation fault on the first `bool=` search of a 3-record database. This hits 64-bit `lind`, `lind512`, `ffi`, `ffi512`
   (LIND without large-file). One-word fix: `#define INFX LONGX`. Applied in the source used for all tests here;
   patch `cisis_infx.patch`.
2. **The banner's `512G` is a fixed string**, printed whenever `_LARGEFILE64_SOURCE` is on (`cidbx.c`, `cicopyr`).
   It is wrong for `isisG` (512 MB) and for `bigisis`/`*G4` (32 GB).
3. **The highest usable MFN of the G4 builds is 2,147,483,521, not 2,147,483,647.** `recxref` computes
   `newpos = (mfn + 126) / 127` in a 32-bit `int` (`cirec.c`, around line 840); from MFN 2,147,483,522 the sum overflows and
   the next `lseek` fails with `recxref/lseek`. Not reachable in practice (the `.xrf` alone would be 8.6 GB) but easy
   to fix by computing in `off_t`/`long long`.
4. `nocc()` and repeating groups stop at 9,999 occurrences although the record holds more (3.2).
5. `mfrl=` above the compiled `MAXMFRL` and `seq=` with very long fields fail **silently** (3.1).
6. `lindG4`/`lind512G4` store 62 bytes less per record than the other 32,767-byte variants (not investigated).
7. **`recxref/read`** (the message that started this study) did **not** appear in any of the 2 × 784 cross-reading cells.
   Reading a database of the other master family always stops earlier, at the first record, with `recread/check/base`.
   It was reproduced one way: when the control record (`nxtmfn` at byte 4 of the `.mst`) announces more records than the `.xrf` file
   holds — `recxref` then tries to read a 512-byte `.xrf` block past the end of the file (`cirec.c`, around line 860). So in
   practice it means a **truncated or mismatched `.xrf`** (copied while open, `.xrf` from another copy of the base, interrupted
   write). If you see it on a database that is healthy for the engine that created it, send the database's first
   bytes (`head -c 64 base.mst | xxd`) and the `.xrf` size; that will say which of the cases it is.

---

## 6. How these numbers were obtained

All binaries are the ones produced by `build_all.sh -u 1` (UTF-8), 32- and 64-bit, on Linux (gcc 13).

| probe | what it does |
|---|---|
| record size | `mx seq=one.txt create=t proc=@big.pft` with a quoted PFT `'a2\|AAAA…\|'` of N bytes, then `mx t pft=f(size(v2),1,0)`; bisection on N |
| key length | one record whose field is a 1000-character word, `fst=1 0 v1`, `fullinv`, then `mx dict=t "pft=v1^s"` (stored length) |
| fields | `proc` string `a1\|x\|` repeated N times; count with `(v1/)` and with `.mst` size |
| tags | `proc='a<T>\|v\|'` for T = 1, 999, 32767, 32768… |
| MFN | edit `nxtmfn` in the `.mst` control record, extend the `.xrf` with a valid last block, `append=` twice |
| `.mst` capacity | a 1 MB (or 30 KB) record doubled with `create=` + `append=` until the file passes 512 MB / 1 GB / 2 GB |
| compatibility | every variant creates a database; every variant reads it (28 × 28 cells); compare master dump, dictionary and 7 searches with what the creator prints |

Not covered: Windows binaries (no compiler here), 8 GB and 32 GB masters, files above 4 GB, the `.ifp`/`.iyp` size limit,
concurrent users (`M` flag), and the ANSI builds (same numbers; only the character handling differs).
