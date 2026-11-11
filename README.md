# XCore Engine (CISIS UTF-8)

XCore Engine is the [ABCD Community](https://abcd-community.org/)'s UTF-8-capable continuation of **CISIS 5.7e**, the C library and command-line utilities for reading, writing, indexing and searching CDS/ISIS databases. It provides `mx` (the general-purpose database utility), `wxis` (the web/CGI interface) and 37 smaller tools, and it is the engine behind ABCD, the open-source library automation system.

CISIS was created by BIREME/PAHO. This project keeps its code, file formats and command-line behaviour, and adds:

- **UTF-8 text handling** (`ciutf8.c`, `ciutf8.h`): case folding, word splitting and truncation, and user-defined character tables (`uctab=`, `actab=`) that work on UTF-8 sequences instead of single bytes. Russian, Hebrew and accented Latin text index and search correctly (covered by the smoke tests).
- **One source tree, two builds.** `UTF8=1` produces the UTF-8 engine; `UTF8=0` produces the classic ANSI (ISO-8859-1) engine from the same files.
- **Clean 64-bit builds on Linux.** Pointer-sized integers (`CIPTR`) in the format compiler and fixes for overlapping copies and out-of-bounds reads, so the 64-bit executables behave like the 32-bit ones.
- **A build and test kit** for Linux (`build_linux.sh`, `smoke_test.sh`, `smoke_test_ansi.sh`) and for Windows with Borland C++ 5.5.

The repository is named `CISIS_UTF8`; the program banner reads `XCore Engine v0.1.0`, with the technology lineage CISIS 5.7e.

## Status

| Target | State |
|---|---|
| Linux 64-bit, UTF-8 | 37 programs build from a clean clone; `smoke_test.sh` passes 21/21 |
| Linux 32-bit, UTF-8 | 37 programs build; `smoke_test.sh` passes 21/21 |
| Linux 32- and 64-bit, ANSI (`-u 0`) | 39 programs build; `smoke_test_ansi.sh` passes 16/16 (ISO-8859-1 data) |
| Linux 64-bit, `bigisis` variant | builds; banner shows 512G; tested with the eight core programs |
| Windows 32-bit, Borland C++ 5.5 | `mx.exe`, `wxis.exe` and six utilities compile on Windows; functional testing inside ABCD is still pending |
| Windows 64-bit (MinGW-w64, MSYS2, Visual Studio) | not verified; see [Windows](#windows) |

The 64-bit and 32-bit executables produce identical output for 758 distinct ABCD print formats (`.pft`) run against a UTF-8 test database, and the eight core programs run clean under AddressSanitizer.

## Programs

The working set is the 37 programs shipped in ABCD's `cgi-bin/ansi` folder plus `crunchif` and `crunchmf`, which ABCD's PHP code also calls: 39 in total, each with its own `.mak` file.

```
crunchif crunchmf i2id id2i ifkeys ifload ifp1 ifupd lydump lyfreq mdl2i mdl2ir
mdlif mdlmf mdlup mkiy0 mkxrf msrt mx mxcp mxf0 mxget mxgw mxmys mxtb mys myz
myzcru mz retag rule serw serw2 serx sizeof sizeof2 splitem splitm wxis
```

- **UTF-8 builds compile 37 of the 39.** `mxgw` and `mz` still read the ANSI word table byte by byte and have not been ported; they build with `-u 0` only.
- **Functional tests** cover `mx`, `wxis`, `ifkeys`, `crunchif`, `crunchmf`, `retag`, `i2id` and `id2i`. The other programs are built and start without crashing, but their output is not yet checked by a test. `ifp1`, `ifupd`, `mdlmf` and `mxtb` were ported to UTF-8 and are in this second group.

## Quick start (Linux)

```bash
# Toolchain (the second line is only needed for 32-bit builds)
sudo apt install build-essential
sudo apt install gcc-multilib libc6-i386

# 64-bit UTF-8 build of all programs  ->  dist/linux64/isis1660/
bash build_linux.sh -a 64 -t all

# Check it
bash smoke_test.sh dist/linux64/isis1660

# Try it
dist/linux64/isis1660/mx
```

`mx` with no arguments prints the banner, which also tells you how the binary was built:

```
XCore Engine v0.1.0/G/PC/W/M/32767/16/60/I/64bits/UTF-8: ... - Utility MX
```

Objects and logs go to `build/`, binaries to `dist/`; neither is tracked by git.

The banner is a code for the build's limits: `M/32767/16/60` means records up to 32,767 bytes and index keys up to 60 bytes; `F` means long records (up to 1,048,576 bytes). [`_docs/LIMITS.md`](_docs/LIMITS.md) explains every field.

### Build options

```
bash build_linux.sh [-a 32|64] [-v VARIANT] [-t "TARGETS"] [-u 0|1] [-x 0|1] [-j N] [-s] [-c]
```

| Option | Meaning | Default |
|---|---|---|
| `-a` | Target architecture, 32 or 64 bit | `32` |
| `-v` | Variant, 14 in all (`-v list`): `isis1660` (ABCD's administrative databases), `bigisis` (ABCD's large databases: records up to 1 MiB, files over 2 GB), `ffi1660`, `isis`, ... see [Variants](#variants) | `isis1660` |
| `-t` | Targets, i.e. `.mak` names without the extension; `all` builds every `.mak` (in UTF-8 mode it skips `mxgw` and `mz` with a warning) | `"mx wxis"` |
| `-u` | `1` = UTF-8 engine, `0` = ANSI engine (output goes to `dist/.../<variant>-ansi`) | `1` |
| `-x` | `1` = honour `uctab=`/`actab=` from the `.par` file (`INCLOADX`) | same as `-u` |
| `-j` | Parallel jobs | `nproc` |
| `-s` | Plain `char` is signed, as in the Borland-built Windows executables | unsigned |
| `-c` | Delete `build/` and `dist/` first | off |

### Variants

CISIS has always been built in several flavours, which differ in the largest record, the longest index key, the largest record number (MFN) and the largest master file. **The files of one flavour cannot be opened safely by another** (the master file, and above all the index). ABCD uses two:

| Variant | Banner | Used by ABCD for |
|---|---|---|
| `isis1660` (default) | `M/32767/16/60` | administrative databases: `acces`, `loanobjects`, `reserve`, `copies`, `servers`, `suggestion`, `trans` |
| `bigisis` | `512G/F/M/1048576/16/256` | large databases (records up to 1 MiB, keys up to 256 bytes) |

There are 12 more, for other needs (keys of 512 bytes, more than 16.7 million records, 4 MiB records...). To build **all of them in one go**:

```bash
bash build_all.sh                  # 14 variants x 32/64 bit, UTF-8, mx + wxis  ->  dist/linux<arch>/<variant>/
bash build_all.sh -u "1 0" -T -p 4 # also the ANSI builds, smoke-test every mx, 4 builds at a time
```

[`_docs/LIMITS.md`](_docs/LIMITS.md) has the exact limits of each variant (record size, key length, MFN, master file size) and a measured table of which variant can read which database. Read its section 4 before pointing a binary at a database it did not create: some combinations fail with a clear error, and a few return wrong answers without any message.

Most people want `-a 64 -t all`. Use `-a 32` for the same 32-bit data model as the Windows executables (add `-s` to also match their signed `char`), for example to compare outputs. 32-bit builds need `libc6-i386`, which lean servers and containers often lack.

## Windows

The official Windows executables are built with **Borland C++ 5.5**. From a Windows prompt in the repository root:

```bat
powershell -ExecutionPolicy Bypass -File find_compilers.ps1
build_windows_bcc55.bat
build_windows_tools_bcc55.bat
```

- `find_compilers.ps1` reports which compilers are installed (BCC55, MinGW, MSYS2, Visual Studio).
- `build_windows_bcc55.bat [isis1660|ffi1660]` builds `mx.exe` and `wxis.exe` into `dist\windows32\<variant>\` (default `isis1660`).
- `build_windows_tools_bcc55.bat [isis1660|ffi1660]` builds `crunchif`, `crunchmf`, `retag`, `ifkeys`, `i2id` and `id2i` into the same folder.
- `build_windows_all_bcc55.bat [utf8|ansi|both] [tools] [variant ...]` builds every variant that exists on Windows (`isis`, `isis1660`, `lind`, `lind512`, `ffi`, `ffi512`, `ffi1660`, `bigisis`), optionally with the utilities. It is generated by `tools/gen_bcc_all.py`. The large-file ("G") variants are Linux-only because Borland C++ 5.5 has no 64-bit seek.

ABCD does not need native 64-bit Windows binaries: 32-bit executables run on 64-bit Windows. A native 64-bit build has groundwork (`CIPTR` is `long long` under `_WIN64`) but has not been completed or run; a MinGW 32-bit build run under Wine failed at run time, and that still has to be reproduced and resolved on a real Windows machine before MinGW can be relied on.

## UTF-8 and ANSI: do not mix them

A database written by one engine must be read by the same kind of engine. Opening an ANSI (ISO-8859-1) database with a UTF-8 binary, or the reverse, corrupts accented characters. Keep the two sets of binaries in separate folders, which `build_linux.sh` does for you.

### Character tables

Indexing and searching beyond basic Latin depend on two tables named in the database's `.par` file:

```
uctab=/path/to/isisuctab_utf8.tab    # upper-case mapping
actab=/path/to/isisactab_utf8.tab    # which characters are letters
```

- The engine only reads the keys `uctab=` and `actab=`.
- The field definition table (FST) should use the `mpu` technique, for example `1 4 mpu,v1`, so keys are upper-cased through `uctab`.
- UTF-8 builds made with `build_linux.sh` or the `.bat` files in this repository enable `INCLOADX`, so the `.par` tables take effect. A build from the bare `.mak` files does not, and then CISIS ignores the tables and only ASCII letters are indexed.
- The official BIREME ANSI builds do not define `INCLOADX`, and neither do the ANSI builds here by default, so ANSI binaries ignore the `.par` tables. `-x 1` turns it on for ANSI as well, but that mode is experimental: 29 of the 39 programs link.
- `tests/` has example tables, including `isisactab_utf8_he.tab`, which adds Hebrew letters (U+05D0 to U+05EA) to the table ABCD ships.

## Repository layout

```
*.c  *.h          core library and program sources
*.mak             one makefile per program (39)
wxis_src/         WXIS sources
build_linux.sh    Linux build driver (one variant)
build_all.sh      Linux: every variant, 32/64 bit, UTF-8/ANSI, with a summary table
build_windows_bcc55.bat, build_windows_tools_bcc55.bat, build_windows_all_bcc55.bat, find_compilers.ps1
smoke_test.sh, smoke_test_ansi.sh
tests/            character tables used by the tests
tools/            maintenance scripts (closure.py, fix_mak_utf8.py, gen_bcc_tools.py, gen_bcc_all.py, limpar_repo.sh)
legacy/           files kept for reference only: old build scripts, makefiles for programs
                  outside the working set, and files that differ from BIREME's tree
_docs/            COMPILING.md (engineering notes), COMPILING_pt-br.md (the Portuguese original), LIMITS.md (limits of every variant)
```

Files that were byte-for-byte identical to BIREME's repository were removed from the working tree; they can be recovered from [github.com/bireme/cisis](https://github.com/bireme/cisis) or from the git tag created before the clean-up (`pre-limpeza-<date>`). Binaries and IDE output are no longer tracked.

## Working on the code

- UTF-8 behaviour lives behind `#if UTF8`. The ANSI branches are left as they were, which is why one tree can build both engines.
- Before sending a change, build with `-a 64 -t all` and with `-a 64 -u 0 -t all`, then run both smoke tests.
- The `.mak` files and shell scripts must keep LF line endings (`.gitattributes` enforces this for `.mak`, `.sh` and `.xsh`); CRLF breaks `make` and `sh` on Linux.

## Known issues

- **WXIS crashes on an unknown `<parm name=...>`.** In `wxis_src/xis_exec.c`, `exeParm()` reads `atValueParm[...]` one position past the array when the parm name does not exist. The official `.exe` files are affected. A guard before `parmIndex = atValueParm[...]` fixes it:
  ```c
  if (cmd->attributeList[ATTRIBUTE_NAME].atValue >= ATVALUE_LIST_QTT) return; /* unknown parm: ignore */
  ```
  This is not yet applied here and has not been confirmed on a rebuilt Windows executable.
- **The code base is CISIS 5.7e; BIREME has moved on.** BIREME's 5.7f (January 2015) widened the record length written by the gizmo routines from 6 to 8 digits (`cigiz.c` here still writes `H%u 000000`). About two dozen of the 156 core sources differ from BIREME's current tree, mixing the UTF-8 work with later upstream fixes. Separating the two needs a three-way merge against the original 5.7e base and has not been done.
- **`crunchmf` and `crunchif` without `target=` convert to the other platform's format.** ABCD's database-conversion page relies on this. To compact in place on the same platform, pass `target=linux` or `target=pc`.
- **Index files are not portable between variants.** Different variants use different index layouts; cross-reading ends in a fatal error in most cases but in some (for example a `lind` index read by `lindG4` in a 32-bit build) searches return wrong results silently. See [`_docs/LIMITS.md`](_docs/LIMITS.md), section 4.
- **The largest usable MFN of the `L4` variants is 2,147,483,521, not 2,147,483,647.** `recxref()` in `cirec.c` computes `(mfn + 126) / 127` in a 32-bit `int`, which overflows. Harmless in practice; the fix is to compute in `off_t`.
- **The `512G` in the banner is a fixed string** printed by every large-file build, whatever the real size limit of the master file is.
- **Compiler warnings.** `gcc -Wall` reports several hundred warnings per program, almost all style (`-Wswitch`, `-Wmissing-braces`, `-Wpointer-sign`). About 70 spots (format strings, int/pointer conversions, implicit declarations) deserve review before enabling `-Werror` for those categories.
- **Limits of the UTF-8 port.** `mxgw` and `mz` are not ported, and a truncated search term that carries an accent in its prefix (for example `ÁGU$`) did not match an `mpu`-indexed `AGUA` in testing; that case has been observed but not investigated.

## 32-bit support

As of November 2026 we found no announced end date for running 32-bit programs on 64-bit Windows 11 or on x86-64 Linux. On Linux the kernel can be started without 32-bit emulation (`ia32_emulation=`), and Debian 13 keeps i386 only for multiarch legacy use, so the practical risk is a server or container without `libc6-i386`. That is why the 64-bit build is the recommended one on Linux. On Windows the 32-bit Borland executables are the ones tested in the field. See `COMPILING.md` for sources and details.

## Roadmap

- Port `mxgw` and `mz` to UTF-8 and add functional tests for the programs that only start without crashing.
- Validate the Windows 32-bit utilities inside ABCD, then bring up a native Windows 64-bit build (MSYS2 or Visual Studio) and run the smoke tests there.
- Merge BIREME's later fixes (5.7f and after) against the 5.7e base.
- Document and test a migration path from ANSI (ISO-8859-1) databases to UTF-8.
- Triage compiler warnings and turn the meaningful categories into errors.

## Documentation

- [`_docs/COMPILING.md`](_docs/COMPILING.md): verification results, the defects fixed, ANSI builds, the 32-bit outlook and repository clean-up notes (Portuguese original: [`_docs/COMPILING_pt-br.md`](_docs/COMPILING_pt-br.md)).
- [`_docs/LIMITS.md`](_docs/LIMITS.md): the exact limits of every variant and which variant can read which database.
- BIREME's original CISIS documentation (manuals for `mx`, the formatting language and the library): <http://wiki.bireme.org/en/index.php/CISIS>

## License

GNU Lesser General Public License, version 2.1. See [`LICENSE`](LICENSE).

## Credits

CISIS is the work of BIREME/PAHO (Latin American and Caribbean Center on Health Sciences Information); the original sources are at [github.com/bireme/cisis](https://github.com/bireme/cisis). CDS/ISIS, the database model CISIS implements, was created by UNESCO. The UTF-8 extensions, the 64-bit fixes and the build kit come from the ABCD community.
