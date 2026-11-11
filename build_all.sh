#!/usr/bin/env bash
# build_all.sh - build EVERY variant in one go (Linux), by calling build_linux.sh in a loop.
#
# Usage:  bash build_all.sh [-a "32 64"] [-v "variants"] [-u "1 0"] [-t "targets"] [-p N] [-j N] [-s] [-T] [-c] [-n]
#   -a  architectures to build (default "32 64")
#   -v  variants (default: all 14, i.e. what "bash build_linux.sh -v list" prints)
#   -u  charsets: "1" = UTF-8 only (default), "0" = ANSI only, "1 0" = both
#   -t  targets for every build (default "mx wxis"; "all" = every .mak, slow)
#   -p  builds running in parallel (default 1). Each build already uses -j make jobs
#   -j  make jobs per build (default: nproc / p)
#   -s  signed char (like the Borland C++ 5.5 .exe); output folders get the "-signed" suffix
#   -T  smoke test every mx after building (create, index, search, banner)
#   -c  delete build/ and dist/ once, before starting
#   -n  dry run: only print what would be built
#
# Output: dist/linux<arch>/<variant>[-signed][-ansi]/<target>   (same layout as build_linux.sh)
# Logs:   build/all/<arch>-<variant>-u<0|1>.log   and   build/all/summary.txt
# Exit status: 0 if everything built (and passed the smoke test, with -T); 1 otherwise.
#
# Examples:
#   bash build_all.sh                       # 14 variants x (32,64 bits) x UTF-8 : mx + wxis
#   bash build_all.sh -u "1 0" -T           # also the ANSI builds, and test every mx
#   bash build_all.sh -a 64 -v "isis ffi1660 lindG4" -t mx
#   bash build_all.sh -p 4 -t all           # everything, 4 builds at a time

set -u
export LC_ALL=POSIX
ROOT=$(cd "$(dirname "$0")" && pwd)
[ -f "$ROOT/build_linux.sh" ] || { echo "ERROR: build_linux.sh not found next to build_all.sh"; exit 1; }

ARCHS="32 64"; VARIANTS=""; CHARSETS="1"; TARGETS="mx wxis"; PAR=1; JOBS=""; SIGNED=""; SMOKE=0; CLEAN=0; DRY=0
while getopts "a:v:u:t:p:j:sTcnh" o; do
  case $o in
    a) ARCHS=$OPTARG;; v) VARIANTS=$OPTARG;; u) CHARSETS=$OPTARG;; t) TARGETS=$OPTARG;; p) PAR=$OPTARG;; j) JOBS=$OPTARG;;
    s) SIGNED="-s";; T) SMOKE=1;; c) CLEAN=1;; n) DRY=1;;
    *) sed -n '2,25p' "$0"; exit 1;;
  esac
done
[ -z "$VARIANTS" ] && VARIANTS=$(bash "$ROOT/build_linux.sh" -v list | tr '\n' ' ')
[ -z "$JOBS" ] && { N=$(nproc 2>/dev/null || echo 2); JOBS=$(( N / PAR )); [ "$JOBS" -lt 1 ] && JOBS=1; }
case $PAR in ''|*[!0-9]*|0) echo "ERROR: -p needs a number >= 1"; exit 1;; esac

LOGD="$ROOT/build/all"; STAT="$LOGD/status"
if [ $CLEAN = 1 ] && [ $DRY = 0 ]; then rm -rf "$ROOT/build" "$ROOT/dist"; fi
mkdir -p "$LOGD"; rm -rf "$STAT"; mkdir -p "$STAT"

# ---- smoke test of one mx: create a database, index it, search it -------------------------
smoke() {  # $1 = path to mx ; prints nothing, returns 0 if OK
  local mx=$1 d r
  d=$(mktemp -d) || return 1
  ( cd "$d" || exit 1
    printf 'alpha beta\ngamma delta\nepsilon zeta\n' > s.txt
    printf '1 4 mpu,v1\n' > s.fst
    "$mx" seq=s.txt create=db now -all   >/dev/null 2>&1 || exit 2
    "$mx" db fst=@s.fst fullinv=db now   >/dev/null 2>&1 || exit 3
    r=$("$mx" db "bool=gamma" "pft=mfn/" now 2>&1 | tail -1)
    [ "$r" = "000002" ] || exit 4
    r=$("$mx" db "pft=v1/" from=3 count=1 now 2>&1 | tail -1)
    [ "$r" = "epsilon zeta" ] || exit 5 )
  r=$?; rm -rf "$d"; return $r
}

# ---- one build (runs in the background when -p > 1) --------------------------------------
build_one() {  # $1 arch  $2 variant  $3 utf8(1|0)
  local a=$1 v=$2 u=$3 id="$1-$2-u$3" t0=$SECONDS suf="" rc=0 st="OK" note=""
  [ -n "$SIGNED" ] && suf="-signed"; [ "$u" = 0 ] && suf="$suf-ansi"
  bash "$ROOT/build_linux.sh" -a "$a" -v "$v" -u "$u" -t "$TARGETS" -j "$JOBS" $SIGNED > "$LOGD/$id.log" 2>&1 || { rc=1; st="BUILD-FAIL"; }
  local dist="$ROOT/dist/linux$a/$v$suf"
  if [ $rc = 0 ] && [ $SMOKE = 1 ]; then
    if [ -x "$dist/mx" ]; then smoke "$dist/mx" && note="smoke ok" || { st="SMOKE-FAIL"; note="smoke failed"; rc=1; }
    else st="NO-MX"; note="mx not in targets"; fi
  fi
  [ $rc = 0 ] || note="$note $(grep -m1 -E 'error|undefined reference|FAILED' "$LOGD/$id.log" | cut -c1-70)"
  local banner=""; [ -x "$dist/mx" ] && banner=$("$dist/mx" 2>&1 | head -1 | sed 's/^[^/]*\///; s/:.*//')
  local cs=ANSI; [ "$u" = 1 ] && cs=UTF-8
  printf '%-4s %-10s %-5s %-11s %4ss  %-34s %s\n' "$a" "$v" "$cs" "$st" "$((SECONDS-t0))" "$banner" "$note" > "$STAT/$id"
  return $rc
}

# ---- loop -----------------------------------------------------------------------------------
TOTAL=0; for a in $ARCHS; do for v in $VARIANTS; do for u in $CHARSETS; do TOTAL=$((TOTAL+1)); done; done; done
echo "== build_all: $TOTAL build(s) | archs: $ARCHS | variants: $(echo $VARIANTS | wc -w) | charsets: $CHARSETS | targets: $TARGETS | parallel: $PAR x -j$JOBS$([ $SMOKE = 1 ] && echo ' | smoke test on')"
if [ $DRY = 1 ]; then for a in $ARCHS; do for v in $VARIANTS; do for u in $CHARSETS; do echo "  would build: arch=$a variant=$v utf8=$u"; done; done; done; exit 0; fi

START=$SECONDS; N=0
for a in $ARCHS; do for v in $VARIANTS; do for u in $CHARSETS; do
  N=$((N+1)); echo "[$N/$TOTAL] $a-bit $v utf8=$u ..."
  if [ "$PAR" -gt 1 ]; then
    while [ "$(jobs -rp | wc -l)" -ge "$PAR" ]; do wait -n 2>/dev/null || sleep 1; done
    build_one "$a" "$v" "$u" &
  else
    build_one "$a" "$v" "$u"
  fi
done; done; done
wait

# ---- summary ---------------------------------------------------------------------------------
{ printf '\n%-4s %-10s %-5s %-11s %5s  %-34s %s\n' bits variant set result time "banner (G/PC/[512G]/W/[F]/[L]/M/<MFRL>/<LE1>/<LE2>/I/..)" notes
  cat "$STAT"/* 2>/dev/null | sort -k1,1n -k3,3 -k2,2; } | tee "$LOGD/summary.txt"
BAD=$(cat "$STAT"/* 2>/dev/null | grep -c -E 'FAIL|NO-MX'); OK=$(cat "$STAT"/* 2>/dev/null | grep -c ' OK ')
echo; echo "== $OK of $TOTAL OK, $BAD failed, $((SECONDS-START))s total. Summary: build/all/summary.txt  logs: build/all/<arch>-<variant>-u<N>.log"
[ "$BAD" = 0 ] && [ "$OK" = "$TOTAL" ]
