# Building CISIS (UTF-8): Linux and Windows, 32 and 64 bit

> English edition of [`COMPILING_pt-br.md`](COMPILING_pt-br.md), updated for the 14 build variants, the new default
> (`isis1660`), `build_all.sh` and the Windows all-variants script. The Portuguese original has not been updated;
> where they disagree, this file is the current one. Exact limits of every variant: [`LIMITS.md`](LIMITS.md).

## What was verified and what was not

| Target | State |
|---|---|
| Linux 32-bit, UTF-8, `isis1660` (default) | ✔ 37 programs build; 21/21 tests (`smoke_test.sh`) |
| Linux 64-bit, UTF-8, default PIE executable (with patches 2 and 3) | ✔ 37 programs; 21/21 tests; earlier, with `ffi1660`: 758 real ABCD formats give **output identical to 32-bit**, AddressSanitizer clean (run on the 8 main programs) |
| Linux 32 and 64-bit, **ANSI** (`-u 0`) | ✔ 39 programs; 16/16 tests (`smoke_test_ansi.sh`, ISO-8859-1 data) |
| Linux, all 14 variants (`build_all.sh -T`) | ✔ 56 of 56 builds (14 variants × 32/64-bit, UTF-8, `mx` + `wxis`); every `mx` creates, indexes and searches a database; limits and compatibility measured in [`LIMITS.md`](LIMITS.md) |
| Windows 32-bit, Borland C++ 5.5: `mx.exe`, `wxis.exe` | ✔ compiled on the maintainer's Windows machine (0 errors, 342 warnings), with what is now `ffi1660`; the other variants are **not run** (see "Windows 32-bit") |
| Windows 32-bit, BCC55: utilities | ✔ compiled there after the `ifkeys.c` patch (the original code gave `E2349` on lines 66 and 76); **functional behaviour inside ABCD still to be tested** |
| Windows 64-bit (MinGW-w64) | **only the compilation was checked** (see "Windows 64-bit"); never run |

## The ABCD programs

The list in ABCD's `cgi-bin/ansi` (37 programs: `i2id id2i ifkeys ifload ifp1 ifupd lydump lyfreq mdl2i mdl2ir mdlif mdlmf mdlup mkiy0 mkxrf msrt mx mxcp mxf0 mxget mxgw mxmys mxtb mys myz myzcru mz retag rule serw serw2 serx sizeof sizeof2 splitem splitm wxis`) plus `crunchif` and `crunchmf` (which ABCD's PHP code uses and which are not in that list) make the **set of 39**. All of them have a `.mak` (the 18 that were missing came from BIREME's original, see patch 3). In **UTF-8** 37 of them build; `mxgw` and `mz` only build in ANSI (see "Programs not yet ported to UTF-8"). `mx wxis ifkeys crunchif crunchmf retag i2id id2i` have a functional test; the others were built and **run without arguments without crashing**, but have no result test. `pdftohtml` is **not part of CISIS** (it belongs to Poppler/Xpdf): on Linux `apt install poppler-utils`; on Windows, a Poppler build. The `.mak` files of `crunchif`, `crunchmf`, `retag`, `i2id`, `id2i`, `mxcp`, `msrt`, `mxf0`, `ifload` and `ifmerge` did not exist in the UTF-8 repository; patch 1 restored them from BIREME, already with `ciutf8.o`. `tools/fix_mak_utf8.py` does the same for other `.mak` files.

## Which variant?

CISIS comes in several build flavours (record size, index key length, record-number width, master-file size). The repository builds the 14 that BIREME's own scripts produce; `bash build_linux.sh -v list` prints them and [`LIMITS.md`](LIMITS.md) gives the exact limits of each one, with a measured table of which variant can read which database. **Do not mix variants on the same database.**

* **`isis1660` is the default**: banner `M/32767/16/60`, records up to 32,767 bytes, keys up to 60 bytes. It is the format of ABCD's administrative databases (`acces`, `loanobjects`, `reserve`, `copies`, `servers`, `suggestion`, `trans`) in the `wxis` that ABCD ships today.
* **`bigisis`**: banner `F/M/1048576/16/256`, records up to 1 MiB, keys up to 256 bytes. It is what ABCD uses for its large databases. It is a different master layout from `isis1660`.
* The other twelve (`isis isisG lind lindG4 lind512 lind512G4 ffi ffiG4 ffiG4_4 ffi512 ffi512G4 ffi1660`) are there for completeness and for the community's future needs.

## Linux

```bash
sudo apt install build-essential            # gcc and make
sudo apt install gcc-multilib libc6-i386    # 32-bit only

bash build_linux.sh                  # 32-bit, isis1660, mx + wxis   -> dist/linux32/isis1660/
bash build_linux.sh -t "mx wxis ifkeys crunchif crunchmf retag i2id id2i"    # the ABCD set
bash build_linux.sh -a 64            # 64-bit (PIE automatically, because cisis.h has CIPTR)
bash build_linux.sh -v bigisis       # ABCD's large databases: records up to 1 MiB, keys up to 256
bash build_linux.sh -v list          # print all 14 variants
bash build_linux.sh -s               # signed char (like BCC55)
bash build_linux.sh -t all           # every .mak (in UTF-8 skips mxgw and mz, with a warning)
bash build_linux.sh -a 64 -u 0 -t all  # ANSI build (UTF8=0) -> dist/linux64/isis1660-ansi/
bash smoke_test.sh dist/linux64/isis1660              # UTF-8
bash smoke_test_ansi.sh dist/linux64/isis1660-ansi    # ANSI (ISO-8859-1 data)
```

Objects go to `build/`, binaries to `dist/`. The banner printed by `mx` identifies the build (`.../M/32767/16/60/I/64bits/UTF-8`).

### Every variant in one go

```bash
bash build_all.sh                        # 14 variants x 32/64 bit x UTF-8, mx + wxis
bash build_all.sh -u "1 0" -T -p 4       # also ANSI; smoke-test every mx; 4 builds at a time
bash build_all.sh -a 64 -v "isis1660 bigisis" -t all
```

`build_all.sh` calls `build_linux.sh` in a loop, keeps one log per build in `build/all/` and prints a summary table (build, banner, result, time). With `-T` each `mx` creates a database, indexes it and searches it. Run `bash build_all.sh -h` for all options.

### 32 or 64 bit

Both work after the patches. Before them, the 64-bit build had two deep problems:

1. **Pointers stored in `int`.** In `SIXTY_FOUR` mode `LONGX` is `int`, and the format (PFT) compiler stored addresses in the `info.add`, `m_add` and `next` fields of `FMT_CODE`, plus `address`/`field_address`, `gen()`, `store_*_const()` and the `rotulos` table. In a PIE executable (the gcc default) this made *any* format segfault. Patch 2 introduces `CIPTR` (an integer the size of a pointer: `long` on Linux 64, `long long` on Windows 64, `long` on 32-bit systems) at those points (154 conversion warnings became 0). `build_linux.sh` uses PIE when `cisis.h` has `CIPTR`, otherwise `-no-pie`.
2. **Copies between overlapping regions** (see below), which the 64-bit `glibc` handles differently from the 32-bit one and which corrupted text: `mdl,v245` printed `Titu de teste /, Autor Exemplolo.` instead of `Titulo de teste /, Autor Exemplo.`.

32-bit is still the most conservative choice (same data model as 32-bit Windows); on a 64-bit Ubuntu it needs `libc6-i386`.

## Defects fixed

All three patches are **already in the repository**.

**Patch 1 (`cisis_fixes_utf8.patch`)**
- `citrm.c`: the end of the dictionary (`highv`) was `0x7F` outside Windows; UTF-8 keys (Russian, Hebrew, accents) compared as "after the end". `ifkeys` listed 7 of 11 terms, truncated searches (`ПРИВ$`) returned 0, and the OPAC term list (`processar_ifkeys.php`) came out incomplete on Linux. Fix: `#if PC || UTF8`.
- `ifkeys.c`: `from=`/`to=` segfaulted (it wrote through a pointer into a string literal).
- `.mak` files without `ciutf8.o` (link error).

**Patch 2 (`cisis_fixes_64bit.patch`)**
- `cisis.h`, `cifm1.c`, `cifm2.c`, `cifm3.c`, `cifmt.h`, `wtrun.c`: `CIPTR` (see above).
- `cifm2.c`, `sub_field_change`: `strcat(q,ps)` with the source inside the destination (undefined behaviour) → `memmove`. It corrupted `mdl`/`mdu` on 64-bit.
- `cifm3.c`: `strcpy(tmp_ptr, sub_string(tmp_ptr,...))` with overlap → `memmove` (120 executions in ABCD's formats).
- `cifm1.c`, `getsymbol`: `ssym[128]` indexed with bytes `> 127` inside **format comments with accents** (`/* ação */`) read outside the array → bounded `SSYM(c)` macro.
- `cifm2.c`, `out_put_str`: read `s[inicio+t]` before testing `t>=0` (1 byte before the buffer).
- `cib71.c`, `gettoken`: the boolean-expression parser read 1 byte before the buffer (`*(p-1)`); new `PREVWHITE(p)`.

The last six apply to **all** platforms (on Windows/BCC55 they silently read garbage).

**Patch 3** added the 18 missing `.mak` files, the UTF-8 port of `ifp1`, `ifupd`, `mdlmf`, `mxtb` and the `splitm.mak` correction (see below).

**Later:** `cisis.h` — in 64-bit LIND builds without large-file support `INFX` was `unsigned int`, but the posting header stores a negative value to mean "bit string"; searches on LIND indexes misread or crashed. Now `#define INFX LONGX` (see [`LIMITS.md`](LIMITS.md), "Surprises").

### How it was verified
- 758 distinct `.pft` formats from ABCD (out of 1944 files) run against a synthetic UTF-8 database: 32-bit and 64-bit PIE identical (758/758, dates masked); under AddressSanitizer, 0 findings after the fixes (there were 3 kinds before).
- 234 boolean searches × 13 FST variants, `crunchif/crunchmf/i2id/id2i/ifkeys` under AddressSanitizer: 0 findings.
- `-s` (signed char, like BCC55): 21/21 as well.

## Behaviour that is not a defect
- `crunchmf`/`crunchif` **without `target=` convert to the format of the OTHER platform** (this is what ABCD's `db_convert_crunchmf.php` relies on). To compact on the same platform: `target=linux` (Linux) or `target=pc` (Windows).
- **`-DINCLOADX=1` is required for multilingual UTF-8**: without it CISIS ignores `uctab=`/`actab=` in the `.par` and Russian/Hebrew are neither indexed nor found. `build_linux.sh` and the generated `.bat` files already pass the flag; the official `.bat` files do not.
- CISIS only reads the keys `uctab=` and `actab=` (not `isisac.tab=`/`isisuc.tab=`). ABCD's `isisactab_utf8.tab` has no Hebrew; `tests/isisactab_utf8_he.tab` adds U+05D0..U+05EA.
- The FST needs `mpu` (`1 4 mpu,v1`). `ÁGU$` (accent in the truncated prefix) does not find `AGUA` indexed with `mpu`: observed, not investigated.

## Windows 32-bit

```powershell
powershell -ExecutionPolicy Bypass -File .\find_compilers.ps1
build_windows_bcc55.bat [isis1660|ffi1660]          # mx.exe and wxis.exe        -> dist\windows32\<variant>\   (default isis1660)
build_windows_tools_bcc55.bat [isis1660|ffi1660]    # the ABCD utilities         -> dist\windows32\<variant>\
build_windows_all_bcc55.bat [utf8|ansi|both] [tools] [variant ...]    # every Windows variant in one go
```

`build_windows_all_bcc55.bat` is generated by `tools/gen_bcc_all.py` and builds `isis isis1660 lind lind512 ffi ffi512 ffi1660 bigisis`. The large-file ("G") variants do not exist on Windows because BCC 5.5 has no 64-bit seek; `bigisis` is built without large-file support there (like BIREME's own Windows `bigisis`), so its files are limited to 2 GiB. The Windows banners start with `PC32` instead of `G/PC`.

BCC55 writes the `.tds` files next to the `.exe`; the `.bat` files delete `%OUT%\*.tds`. The official `.exe` files use signed `char` (no `-K`).

**What was and was not run:** `mx.exe` and `wxis.exe` (0 errors, 342 warnings) and the utilities (after the `ifkeys.c` patch; the original code gave `E2349` on lines 66 and 76) were compiled on the maintainer's Windows machine, with the variant that was then the default (today's `ffi1660`). The `isis1660` default, `build_windows_all_bcc55.bat` and the Windows `bigisis` variant have **not** been run on Windows (there is no Windows or wine here); neither has the compatibility between ABCD's current Windows `wxis` (CISIS 5.2bb, `PC32/W/M/32767/16/60/I`) and a new `isis1660` build. The functional behaviour of the utilities inside ABCD is also still to be tested.

## Windows 64-bit

For ABCD this is **not necessary**: the 32-bit `.exe` files run on 64-bit Windows. If a native 64-bit build is wanted:
- **Already done:** `CIPTR` becomes `long long` under `_WIN64` (64-bit Windows is LLP64: `long` is 32 bits). With 64-bit MinGW-w64, `cifm1.c`, `cifm2.c`, `cifm3.c`, `cib72.c`, `cidbx.c` and `cirec.c` compile and **1** pointer/integer conversion warning remains (a debug line at `cib72.c:2852`).
- **Missing:** compiling and **running** the whole set. The routes would be MSYS2 (`mingw-w64-x86_64-gcc`) or Visual Studio 2022 (`cl.exe`, flag `MSC`). A test with 32-bit MinGW under wine failed at run time (`format syntax | Invalid operand class` in `replace(s(cat(...)))`); that must be reproduced and solved on a real Windows machine before MinGW can be relied on. The MinGW portability patches are also still missing in the code (`alloc.h`, `sys\stat.h`, sockets, `_rtl_*`, `lock`/`unlock`, `O_DENYNONE`, `MAXPATH`).
- Suggestion: first validate `mx` on MSYS2 with `smoke_test.sh` (it needs bash, which MSYS2 provides).

## Compiler warnings
**BCC55** (175 distinct): 154 are style; the rest are harmless or worth reviewing: `cifm2.c:604,633` (missing cast in `strlen_UTF8`/`skipchar_UTF8`), `easyfc.c:171-197` (missing `#include <io.h>`), `cisisx.c:2539` (`LSEEK64(fd,-sizeof(...))` negates a `size_t`; review in the large variants), `cifst.c:1534` (comparison always false).
**gcc 32-bit `-Wall`** (~3,500 occurrences): almost all noise (`-Wswitch` 2145, `-Wmissing-braces` 382, `-Wpointer-sign` 362, `-Wattributes` 290). Places that may hide a defect: ~70 (`-Wformat` 30, `-Wformat-overflow` 10, `-Wint-conversion` 7, `-Wimplicit-function-declaration` 7, `-Wformat-security` 4, `-Wmaybe-uninitialized` 3, ...). Plan: triage those, fix them, and turn on `-Werror=` for those categories only.

## Programs not yet ported to UTF-8
`mxgw` and `mz` read the `isiswctab` table byte by byte to split words; in UTF-8 this requires rewriting the loop with `alphabetic_utf8()`/`skipchar_utf8()` (as already done in `cifm3.c` and `mxrel.c`). They build in ANSI (`-u 0`) and stay that way until ported. The others (`ifp1`, `ifupd`, `mdlmf`, `mxtb`) were ported in patch 3 (`uppercase_utf8`, `loaductb_utf8`/`loadactb_utf8`, `isisuctab_utf8` in `b7_run`) and **only have build and start-up tests**, with no functional test of results.
`splitm`: the repository's `.mak` had an extra `ciutf8.o` and failed to link; patch 3 goes back to BIREME's version (the program does not use the library).

## Two source trees
`CISIS_UNI_Win/sources` is **not BIREME's original** (the original, github.com/bireme/cisis, has no `UTF8` in `cisis.h` and no `ciutf8.c`). It is an already modified tree (UTF-8, v6.0a) that produced the official `.exe` files and differs from the root (for example `cifm3.c:580` has `p++;q++;`). Keep it on a branch or in `legacy/`.

## Known WXIS bug: unknown parm
`xis_exec.c`, `exeParm()`: `cplIdentifier()` returns `ATVALUE_LIST_QTT` for names of nonexistent parms and `atValueParm[...]` is read with that index (one position past the array). In the official `.exe` files this crashes WXIS (`crear_registro.xis` had `MAX_TMP_STRING`). Fix, before `parmIndex = atValueParm[...]`:
```c
if (cmd->attributeList[ATTRIBUTE_NAME].atValue >= ATVALUE_LIST_QTT) return; /* unknown parm: ignore */
```
Not yet confirmed by rebuilding a Windows `.exe`.

## Building in ANSI (`UTF8=0`)
It works: `bash build_linux.sh -u 0 ...` passes `-DUTF8=0` and writes to `dist/.../<variant>-ansi`. Verified: all 39 programs build in 32 and 64 bit and `smoke_test_ansi.sh` gives 16/16 with ISO-8859-1 data. The same tree produces both versions, but **do not mix them**: an ANSI database with a UTF-8 binary (and the reverse) corrupts accents.

Mind the `.par`: no BIREME `.mak` (nor the ones in this repository) defines `INCLOADX`, so an ANSI binary built like them **ignores `uctab=`/`actab=` in the `.par`**. Without a table only ASCII counts as letters, and `Água e Ação` is indexed as `A`, `GUA`, `O` (verified with `ifkeys`). That is why `smoke_test_ansi.sh` passes the tables as `mx` options.
`-x 1` turns `INCLOADX` on in ANSI and the `.par` takes effect (verified: `água` 2 results, `AGU$` 2, `ça` 1, using only the `.par`), but **it is experimental**: 29 of 39 link; `ifkeys lydump lyfreq mdl2i mdl2ir mkiy0 myz myzcru sizeof splitem` do not (their `.mak` files link few objects; just adding `ciutl.o` is not enough, `recxrefb` shows up). Do not use `-x 1` for the ABCD set before deciding this: it changes how existing ANSI databases are indexed.

## How long will 32-bit binaries keep working?
No end date has been announced, on either system. What was checked:
- **Windows (x64):** Windows 11 only exists in 64-bit and still runs 32-bit programs (WOW64); an article of 20 Oct 2026 shows WOW64 working on Windows 11 26H2 and reports no removal plan ([Windows Latest](https://www.windowslatest.com/2026/10/20/why-windows-11-keeps-64-bit-files-in-system32-and-32-bit-files-in-syswow64-according-to-microsoft/)); another, of 9 May 2026, says the same and that 25H2 no longer installs on old x86 hardware ([Born City](https://borncity.com/news/windows-11-microsoft-verabschiedet-sich-von-32-bit-aber-nicht-von-alter-software/)). The removal that does exist is of **ARM32** applications on Windows on ARM, which does not affect x64 ([WinFuture](https://winfuture.de/news,137385.html)). Microsoft's documentation could not be opened (blocked in the environment used), so there is no official citation.
- **Linux (x86-64):** the kernel runs 32-bit code through `IA32_EMULATION`; since 6.7 it can be turned off at boot (`ia32_emulation=`) and distributions were studying turning it off by default ([Phoronix](https://phoronix.com/news/Linux-6.8-x86-32-bit-Warning)). The 2026 kernel discussion is about **x32**, a different ABI, not about the i386 that `-m32` uses ([LWN, 1 Jun 2026](https://lwn.net/Articles/1074897/)). In Debian 13, i386 stopped being a full architecture and remains only to run legacy code through multiarch ([The Register](https://www.theregister.com/2025/08/12/debian_13_trixie_released/)). Here, on Ubuntu 24.04 with kernel 6.18, the 32-bit binaries built and ran in this round.
- **Practical risk:** it is not Windows but lean Linux servers or containers without `libc6-i386`. That is why the 64-bit PIE build (with patches 2 and 3) is the choice for Linux; on Windows the 32-bit (BCC55) `.exe` files remain the ones tested in the field.

## Repository clean-up (done)
Before the clean-up the HEAD had 554 tracked files (21 MB). `tools/limpar_repo.sh` (kept for the record) separated them into:
- **kept 182**: the dependency closure of the 39 programs + `wxis` (computed from the `.mak` files and `gcc -MM`; `tools/closure.py` redoes the calculation) and the kit;
- **deleted 313**: binaries (`1660utf8/` with 35 Linux executables, `ifkeys`, `main.o`, `wxis.exe`), Borland IDE output (`mx.csm` 3 MB, `.ils .ilf .ilc .ild .mbt .mrt .DSW`), `err.out`, `cisis.h.save*`, stray copies (`ciutf8.c2`, `easyfc(1).c`, `easyfc.c.57e*`) and **245 files identical to BIREME's original** (other programs, the C++ version, the wxis examples), recoverable from https://github.com/bireme/cisis or from the safety tag;
- **moved 59 to `legacy/`**: what differs from BIREME or exists only here (`makemake*`/`mk*`/`generateAll*` scripts, `.mak` files of programs outside the ABCD list, `cifm3_standard.c`, Borland's `stdio.h`, `changes.txt` of the 5.7e tree).
Proof: a tree assembled with only what stays builds and passes the same tests (37 and 39 binaries; 21/21 and 16/16). The script printed a dry run first and applied with `--aplicar`, creating the tag `pre-limpeza-YYYYMMDD` and using `git rm`/`git mv`, so the history is kept. `legacy/` can be deleted later; the wxis examples (123 files) were removed because they are identical to BIREME's; to keep them as documentation, take them out of the `APAGAR` list.

## The UTF-8 tree is 5.7e; BIREME moved on
BIREME's `changes.txt` records **5.7f (13 Jan 2015)**: the record length in the gizmo went from 6 to 8 digits. Checked in the code: `cigiz.c` in this tree still writes `H%u 000000` (lines 561-562 and 631), BIREME writes `00000000`. Of the 156 core sources/headers, **26 differ** from BIREME's HEAD (130 identical, 4 only here: `ciutf8.c`, `ciutf8.h`, `easyfc.c`, `stdio.h`). The differences mix the UTF-8 work (`cisis.h`, `cirun.h`, `cifm3.c`, `cifst.c`, `cib72.c`, `mxaot.c`, `ciupdsplt.c`...) with later fixes that are missing here. The two have **not yet been separated**: that needs the original 5.7e base (BIREME's history) for a three-way merge.
