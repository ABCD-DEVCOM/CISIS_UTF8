#!/usr/bin/env bash
# smoke_test.sh - quick test of mx and wxis in UTF-8 (accents, Russian, Hebrew).
# Usage: bash smoke_test.sh dist/linux64/utf8/isis1660        (run it from the repository root)
# The character tables it uses are in tests/ (an actab with Hebrew letters added).
set -u
export LC_ALL=POSIX
D=${1:-}
[ -x "$D/mx" ] && [ -x "$D/wxis" ] || { echo "usage: $0 <folder with mx and wxis>   e.g. dist/linux64/utf8/isis1660"; exit 1; }
D=$(cd "$D" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
TAB="$HERE/tests"
[ -f "$TAB/isisuctab_utf8.tab" ] && [ -f "$TAB/isisactab_utf8_he.tab" ] || { echo "ERROR: character tables missing in $TAB"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
PASS=0; FAILN=0
ok()   { echo "  [ok]    $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL]  $1"; FAILN=$((FAILN+1)); }

printf '%s\n' 'Água e Ação' 'ÁGUA' 'Привет мир' 'שלום עולם' 'Ça va très bien' > data.txt
printf 'uctab=%s\nactab=%s\n' "$TAB/isisuctab_utf8.tab" "$TAB/isisactab_utf8_he.tab" > t.par
printf '1 4 mpu,v1\n' > db.fst

# 1) load and read back (byte-for-byte round trip)
"$D/mx" seq=data.txt create=db now -all >/dev/null 2>&1
"$D/mx" db "pft=v1/" now > back.txt 2>/dev/null
cmp -s data.txt back.txt && ok "mx: load and read back (identical round trip)" || fail "mx: round trip differs"
N=$("$D/mx" db count=100 "pft=mfn/" now 2>/dev/null | wc -l)
[ "$N" = 5 ] && ok "mx: 5 records stored" || fail "mx: expected 5 records, found $N"

# 2) indexing with the UTF-8 tables read from the .par file, then searches
"$D/mx" cipar=t.par db "fst=@db.fst" fullinv=db now >/dev/null 2>&1
search() { "$D/mx" cipar=t.par db "bool=$1" "pft=mfn/" now 2>/dev/null | grep -o 'Hits=[0-9]*' | cut -d= -f2; }
check() { # term, expected, label
  R=$(search "$1"); [ "$R" = "$2" ] && ok "mx: search '$1' ($3) -> $R hit(s)" || fail "mx: search '$1' ($3): expected $2, got '${R:-?}'"; }
check 'ÁGUA'    2 "accented upper case"
check 'água'    2 "accented lower case finds ÁGUA/Água"
check 'ça'      1 "cedilla"
check 'привет'  1 "Russian"
check 'ПРИВЕТ'  1 "Russian, upper case"
check 'שלום'    1 "Hebrew"
check 'עולם'    1 "Hebrew"

# 2b) truncated search ($): walks the dictionary in sequence (uses the highv terminator)
check 'ПРИВ$'  1 "Russian, truncated"
check 'שלו$'    1 "Hebrew, truncated"
check 'AGU$'    2 "Latin, truncated"

# 2c) utilities used by ABCD (only the ones present in the folder are tested)
tem() { [ -x "$D/$1" ]; }
if tem i2id && tem id2i; then
  "$D/i2id" db > a.id 2>/dev/null
  "$D/id2i" a.id create=db_id >/dev/null 2>&1
  "$D/mx" db_id "pft=v1/" now > back_id.txt 2>/dev/null
  cmp -s data.txt back_id.txt && grep -q 'שלום עולם' a.id && ok "i2id + id2i: identical UTF-8 round trip" || fail "i2id + id2i: round trip differs"
fi
if tem crunchmf; then
  # without target, crunchmf converts to the format of the OTHER platform (this is what ABCD's db_convert_crunchmf.php uses)
  "$D/crunchmf" db db_cmf_pc >/dev/null 2>&1
  [ -s db_cmf_pc.mst ] && [ -s db_cmf_pc.xrf ] && ok "crunchmf: default target (other platform) writes .mst/.xrf" || fail "crunchmf: default target wrote no files"
  "$D/crunchmf" db db_cmf target=linux >/dev/null 2>&1
  "$D/mx" db_cmf "pft=v1/" now > back_cmf.txt 2>/dev/null
  cmp -s data.txt back_cmf.txt && ok "crunchmf target=linux: crunched database reads like the original" || fail "crunchmf target=linux: content differs"
fi
if tem crunchif && tem ifkeys; then
  cp db.mst db_cif.mst; cp db.xrf db_cif.xrf
  "$D/crunchif" db db_cif target=linux >/dev/null 2>&1
  N=$("$D/ifkeys" db_cif 2>/dev/null | wc -l)
  [ "$N" = 11 ] && ok "crunchif target=linux: crunched index with the 11 terms" || fail "crunchif target=linux: ifkeys lists $N terms (expected 11)"
fi
if tem retag; then
  cp db.mst db_rt.mst; cp db.xrf db_rt.xrf; printf '1 2\n' > retag.tab
  "$D/retag" db_rt retag.tab >/dev/null 2>&1
  V2=$("$D/mx" db_rt "pft=v2/" now 2>/dev/null); V1=$("$D/mx" db_rt "pft=v1/" now 2>/dev/null)
  cmp -s <(printf '%s' "$V2") <(printf '%s' "$(cat data.txt)") 2>/dev/null && [ -z "$V1" ] && ok "retag: field 1 became 2 without changing the UTF-8 text" || fail "retag: unexpected result"
fi
if tem ifkeys; then
  K=$("$D/ifkeys" db 2>/dev/null | sed 's/^ *[0-9]*|//' | tr '\n' ' ')
  [ "$K" = "ACAO AGUA BIEN CA E TRES VA МИР ПРИВЕТ עולם שלום " ] && ok "ifkeys: lists the 11 terms (Latin, Russian, Hebrew)" || fail "ifkeys: incomplete list: $K"
  K2=$("$D/ifkeys" db from=ПРИВЕТ 2>&1 | sed 's/^ *[0-9]*|//' | tr '\n' ' ')
  [ "$K2" = "ПРИВЕТ עולם שלום " ] && ok "ifkeys from=ПРИВЕТ: does not hang and lists the following terms" || fail "ifkeys from=: '$K2'"
fi

# 3) wxis reads the database and returns the same text
cat > read.xis <<XIS
<IsisScript><section><do task=mfnrange><parm name=db>$T/db</parm><parm name=from>1</parm><parm name=to>5</parm><loop><display><pft>v1/</pft></display></loop></do></section></IsisScript>
XIS
"$D/wxis" IsisScript=read.xis > wxis_out.txt 2>/dev/null
cmp -s data.txt wxis_out.txt && ok "wxis: reads 5 records (identical to the original)" || fail "wxis: output differs"

# 4) wxis writes a new record received by POST (as ABCD does with crear_registro.xis)
cat > write.xis <<XIS
<IsisScript><section>
<field action=cgi tag=9010>ValorCapturado</field>
<do task=update><parm name=db>$T/db</parm><parm name=mfn>New</parm>
<update><field action=define tag=1102>Isis_Status</field><field action=import tag=9010>9010</field>
<proc><pft>v9010</pft></proc><proc><pft>'d9010'</pft></proc><write>Unlock</write>
<display><pft>mfn</pft></display></update></do></section></IsisScript>
XIS
BODY="IsisScript=$T/write.xis&ValorCapturado=%3C1+0%3ENova+a%C3%A7%C3%A3o+%D7%A9%D7%9C%D7%95%D7%9D+%2520+%C3%87a%3C%2F1%3E"
R=$(printf '%s' "$BODY" | REQUEST_METHOD=POST CONTENT_TYPE=application/x-www-form-urlencoded CONTENT_LENGTH=${#BODY} "$D/wxis" 2>/dev/null | tr -d '\n ')
V=$("$D/mx" db from=6 count=1 "pft=v1/" now 2>/dev/null)
[ "$((10#${R:-0}))" = 6 ] && [ "$V" = 'Nova ação שלום %20 Ça' ] && ok "wxis: write via POST (accents, Hebrew, literal %20)" || fail "wxis: write via POST (mfn='$R', value='$V')"

echo "== $PASS ok, $FAILN failure(s)"
[ $FAILN = 0 ]
