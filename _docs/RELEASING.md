# Making a release

How the downloadable packages of a release are produced. The text of each release lives in [`release-notes/`](release-notes/).

## 1. Commit first

The binaries must match a commit, so everything goes into git before building. `tools/package_release.sh` refuses to run on a working tree with uncommitted changes (`-f` overrides this, for trial runs only).

## 2. Build

Linux (64-bit; add `32` to `-a` if you also want 32-bit packages):

```bash
bash build_all.sh -c -A -T
```

`-A` builds the ABCD set (`isis1660` and `bigisis`, ANSI and UTF-8, every program) and lays it out like ABCD's `cgi-bin` in `dist/abcd/linux64/`; `-c` starts from a clean `build/` and `dist/`; `-T` creates, indexes and searches a database with every `mx`. The summary must say `4 of 4 OK`.

Windows (Borland C++ 5.5), in the same folder of the repository:

```
build_windows_all_bcc55.bat > build_windows_all.log 2>&1
```

With no arguments it builds the ABCD set into `dist\abcd\windows32\`. The end of the log must say `ALL OK`; anything listed as `NOT BUILT` must be explained in the release notes.

When the repository folder is shared between Windows and WSL (for example `C:\xampp\htdocs\CISIS_UTF8` = `/mnt/c/xampp/htdocs/CISIS_UTF8`), both builds end up in the same `dist/` and one packaging run takes both.

## 3. Test before publishing

At least, for each operating system you publish:

- [ ] `smoke_test.sh dist/linux64/utf8/isis1660` and `smoke_test_ansi.sh dist/linux64/ansi/isis1660` pass (Linux).
- [ ] The ANSI binaries (`cgi-bin/ansi`) are used with the ANSI databases, the UTF-8 ones with UTF-8 databases; accented text looks right in both.
- [ ] A copy of ABCD with the new `cgi-bin` opens the administrative databases (`acces`, `loanobjects`, `reserve`, `copies`, `servers`, `suggestion`, `trans`): login, loans, reservations, search.
- [ ] A `bigisis` database opens, searches and saves a record.
- [ ] A record edited with the new `wxis` reads back the same with the old binary, and the other way round (on copies).
- [ ] An index rebuilt with the new binaries gives the same search results as before.
- [ ] Accented text (ANSI) and non-Latin text (UTF-8) display, index and search correctly.

## 4. Package

```bash
bash tools/package_release.sh -v v0.1.0-alpha.1
```

It writes `release/<version>/`:

- `xiscore-<version>-linux64-abcd.tar.gz`, from `dist/abcd/linux64/` (made by `build_all.sh -A`);
- `xiscore-<version>-windows32-abcd.zip`, from `dist/abcd/windows32/`;
- `SHA256SUMS.txt`.

Each package carries `LICENSE`, `README.md`, `INSTALL.txt` and `BUILDINFO.txt` (commit, date, compiler, the banner of every `mx` that can run on the packaging machine, and the SHA-256 of every file). A missing part is skipped with a warning, so read the output.

## 5. Publish

1. Tag the commit and push the tag:
   ```bash
   git tag -a v0.1.0-alpha.1 -m "XisCore Engine v0.1.0-alpha.1 (test release)"
   git push origin v0.1.0-alpha.1
   ```
2. On GitHub: *Releases → Draft a new release*, choose the tag, paste `release-notes/<version>.md`, attach the files of `release/<version>/` and tick **Set as a pre-release** while the version has `-alpha` or `-beta` in its name.

## Version names

`v0.1.0-alpha.N` while the binaries are being tested in ABCD; `v0.1.0-beta.N` once the checklist above passes on both systems with real databases; `v0.1.0` when it can replace the binaries ABCD ships. The banner (`XisCore Engine v0.1.0`) is set in the source and changes only with the version number, not with the `-alpha`/`-beta` suffix.
