#!/usr/bin/env bash
# build_linux.sh - build CISIS / XisCore Engine programs (mx, wxis, ...) on Linux, from the repository root.
#
# Usage:  bash build_linux.sh [-a 32|64] [-v VARIANT] [-t "targets"] [-u both|1|0] [-x 0|1] [-j N] [-s] [-c]
#   -a  architecture: 32 (default, safest) or 64 (see _docs/COMPILING.md)
#   -v  variant (default isis1660, the format of ABCD's administrative databases; ABCD's large databases use bigisis).
#       "-v list" prints all of them; _docs/LIMITS.md gives the exact limits of each:
#         isis isisG isis1660 lind lindG4 lind512 lind512G4 ffi ffiG4 ffiG4_4 ffi512 ffi512G4 ffi1660 bigisis
#   -t  targets (.mak names without the extension). Default: "mx wxis". "all" = every .mak
#   -u  character set: "both" (default: the UTF-8 engine, then the ANSI one), 1 = UTF-8 only, 0 = ANSI only
#   -x  INCLOADX: 1 = read uctab=/actab= from the .par file; 0 = ignore it. Default: same as -u
#       (BIREME's official ANSI builds ignore them)
#   -j  parallel jobs (default: nproc)
#   -s  build with SIGNED char (like the Borland C++ 5.5 used for the official .exe); default: -funsigned-char
#   -c  delete build/ and dist/ before building
#
# Output: dist/linux<arch>/utf8/<variant>/<target>  and  dist/linux<arch>/ansi/<variant>/<target>
#         (logs in build/<arch>-<utf8|ansi>-<variant>/logs; "-signed" / "-par" are added to <variant> with -s / -x)
# Object files stay in build/, the source tree is not touched.

set -u
export LC_ALL=POSIX

# ---- variants: same set as BIREME's makemake*.xsh / mk*.xsh scripts -------------------------
# columns: CIFFI LIND LIND4 ISISXL ISISXL512 SUPERISIS _FILE_OFFSET_BITS _LARGEFILE64_SOURCE [MAXMFRL]
VARIANT_NAMES="isis isisG isis1660 lind lindG4 lind512 lind512G4 ffi ffiG4 ffiG4_4 ffi512 ffi512G4 ffi1660 bigisis"
variant_row() {
  case $1 in
    isis)      echo "0 0 0 0 0 0 00 0";;
    isisG)     echo "0 0 0 0 0 0 64 1";;
    isis1660)  echo "0 0 0 1 0 0 00 0";;
    lind)      echo "0 1 0 1 0 0 00 0";;
    lindG4)    echo "0 1 1 1 0 0 64 1";;
    lind512)   echo "0 1 0 1 1 0 00 0";;
    lind512G4) echo "0 1 1 1 1 0 64 1";;
    ffi)       echo "1 1 0 1 0 0 00 0";;
    ffiG4)     echo "1 1 1 1 0 0 64 1";;
    ffiG4_4)   echo "1 1 1 1 0 0 64 1 4194304";;
    ffi512)    echo "1 1 0 1 1 0 00 0";;
    ffi512G4)  echo "1 1 1 1 1 0 64 1";;
    ffi1660)   echo "1 0 0 1 0 0 00 0";;
    bigisis)   echo "1 0 0 1 0 1 64 1";;
    *)         return 1;;
  esac
}

ORIG_ARGS=("$@")
ARCH=32; VARIANT=isis1660; TARGETS="mx wxis"; UTF8=both; JOBS=$(nproc 2>/dev/null || echo 2); CLEAN=0; SIGNED=0; INCX=""
while getopts "a:v:t:u:x:j:csh" o; do
  case $o in
    a) ARCH=$OPTARG;; v) VARIANT=$OPTARG;; t) TARGETS=$OPTARG;; u) UTF8=$OPTARG;; x) INCX=$OPTARG;; j) JOBS=$OPTARG;; c) CLEAN=1;; s) SIGNED=1;;
    *) sed -n '2,18p' "$0"; exit 1;;
  esac
done

if [ "$VARIANT" = list ]; then echo "$VARIANT_NAMES" | tr ' ' '\n'; exit 0; fi

# "-u both": build the UTF-8 engine, then the ANSI one, with the same options (-c is done only once, here)
case $UTF8 in
  both) if [ $CLEAN = 1 ] && [ -z "${CISIS_NOCLEAN:-}" ]; then R=$(cd "$(dirname "$0")" && pwd); rm -rf "$R/build" "$R/dist"; fi
        RC=0
        CISIS_NOCLEAN=1 bash "$0" "${ORIG_ARGS[@]}" -u 1 || RC=1
        echo
        CISIS_NOCLEAN=1 bash "$0" "${ORIG_ARGS[@]}" -u 0 || RC=1
        exit $RC;;
  0|1) ;;
  *) echo "ERROR: -u must be both, 1 (UTF-8) or 0 (ANSI)"; exit 1;;
esac

ROOT=$(cd "$(dirname "$0")" && pwd)
[ -f "$ROOT/cisis.h" ] || { echo "ERROR: run this script from the repository root (where cisis.h is)"; exit 1; }
command -v gcc  >/dev/null || { echo "ERROR: gcc not found (sudo apt install build-essential)"; exit 1; }
command -v make >/dev/null || { echo "ERROR: make not found (sudo apt install build-essential)"; exit 1; }

ROW=$(variant_row "$VARIANT") || { echo "ERROR: unknown variant: $VARIANT (use -v list)"; exit 1; }
set -- $ROW
V="CIFFI=$1 LIND=$2 LIND4=$3 ISISXL=$4 ISISXL512=$5 SUPERISIS=$6 _FILE_OFFSET_BITS=$7 _LARGEFILE64_SOURCE=$8"
[ $# -ge 9 ] && V="$V MAXMFRL=$9"

# ---- architecture ----
case $ARCH in
  32) CC="gcc -m32";             V="$V SIXTY_FOUR=0"
      T32=$(mktemp -d)    # private folder: build_all.sh may run several builds at the same time
      echo 'int main(void){return 0;}' > "$T32/t.c"
      if gcc -m32 "$T32/t.c" -o "$T32/t" 2>/dev/null && "$T32/t"; then rm -rf "$T32"; else
        rm -rf "$T32"; echo "ERROR: gcc -m32 does not work. Install:  sudo apt install gcc-multilib libc6-i386"; exit 1; fi;;
  64) V="$V SIXTY_FOUR=1"
      # Without the CIPTR fields (compiler pointers stored in int) only non-PIE works.
      # With the patch applied (cisis.h defines CIPTR) the default PIE executable is safe.
      if grep -q "CIPTR" "$ROOT/cisis.h"; then CC="gcc"; else CC="gcc -no-pie -fno-pie"; echo "WARNING: cisis.h has no CIPTR: building 64-bit non-PIE (fragile)"; fi
      ;;
  *) echo "ERROR: -a must be 32 or 64"; exit 1;;
esac
CCFLAGS="-funsigned-char -Wall -DUTF8=$UTF8"
[ $SIGNED = 1 ] && CCFLAGS="-fsigned-char -Wall -DUTF8=$UTF8"
# INCLOADX=1: without it CISIS ignores uctab=/actab= from the .par file and does not index/search
# words outside basic Latin (Russian, Greek, Hebrew...). See _docs/COMPILING.md.
[ -z "$INCX" ] && INCX=$UTF8        # default: on for UTF-8, off for ANSI (like BIREME's official binaries)
[ "$INCX" = 1 ] && CCFLAGS="$CCFLAGS -DINCLOADX=1"

if [ "$TARGETS" = "all" ]; then
  TARGETS=$(cd "$ROOT" && ls *.mak | sed 's/\.mak$//' | tr '\n' ' ')
  # mxgw and mz still use the ANSI tables directly (isiswctab) and are not ported to UTF-8:
  # with "all" they are only built in the ANSI tree. With an explicit -t the script tries anyway.
  if [ "$UTF8" = 1 ]; then TARGETS=$(for t in $TARGETS; do case $t in mxgw|mz) echo "WARNING: $t skipped in UTF-8 (not ported yet; they are built in the ANSI tree)" >&2;; *) printf '%s ' $t;; esac; done); fi
fi

CS=utf8; [ "$UTF8" = 0 ] && CS=ansi   # UTF-8 and ANSI builds go to separate trees: dist/linux64/utf8/..., dist/linux64/ansi/...
SUF=""; [ $SIGNED = 1 ] && SUF="-signed"
[ "$UTF8" = 0 ] && [ "$INCX" = 1 ] && SUF="$SUF-par"   # ANSI reading uctab=/actab= from the .par: dist/linux64/ansi/isis1660-par
REL="dist/linux$ARCH/$CS/$VARIANT$SUF"
BUILD="$ROOT/build/$ARCH-$CS-$VARIANT$SUF"; WORK="$BUILD/work"; LOGS="$BUILD/logs"
DIST="$ROOT/$REL"
[ $CLEAN = 1 ] && [ -z "${CISIS_NOCLEAN:-}" ] && rm -rf "$ROOT/build" "$ROOT/dist"
mkdir -p "$WORK" "$LOGS" "$DIST"

# working copy (object files outside the source tree); .mak files converted to LF
rm -rf "$WORK"; mkdir -p "$WORK"
(cd "$ROOT" && cp -- *.c *.h *.mak "$WORK"/ 2>/dev/null; [ -d wxis_src ] && cp -r wxis_src "$WORK"/)
sed -i 's/\r$//' "$WORK"/*.mak

echo "== CISIS | arch=$ARCH | variant=$VARIANT$SUF | $CS (UTF8=$UTF8) | gcc $(gcc -dumpversion) | targets: $TARGETS"
FAIL=0; SUMMARY=""
for t in $TARGETS; do
  if [ ! -f "$WORK/$t.mak" ]; then SUMMARY="$SUMMARY\n  $t: MISSING $t.mak"; FAIL=1; continue; fi
  ( cd "$WORK" && rm -f -- *.o "$t" wxis_src/*.o 2>/dev/null
    make -j"$JOBS" -f "$t.mak" CC="$CC" CCFLAGS="$CCFLAGS" $V > "$LOGS/$t.log" 2>&1 )
  if [ -x "$WORK/$t" ]; then
    cp "$WORK/$t" "$DIST/$t"
    W=$(grep -c 'warning:' "$LOGS/$t.log")
    SUMMARY="$SUMMARY\n  $t: OK  ($W warnings)  -> $REL/$t"
  else
    E=$(grep -m1 -E 'error|undefined reference' "$LOGS/$t.log" | cut -c1-110)
    SUMMARY="$SUMMARY\n  $t: FAILED  ${E}  (log: build/$ARCH-$CS-$VARIANT$SUF/logs/$t.log)"; FAIL=1
  fi
done
printf "$SUMMARY\n"

# banner check (mx)
if [ -x "$DIST/mx" ]; then
  B=$("$DIST/mx" 2>&1 | head -1); echo "== banner: $B"
  if [ "$UTF8" = 1 ]; then case $B in *UTF-8*) :;; *) echo "WARNING: UTF-8 was requested but the banner does not say UTF-8"; FAIL=1;; esac; fi
fi
exit $FAIL
