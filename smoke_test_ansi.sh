#!/usr/bin/env bash
# smoke_test_ansi.sh - quick test of mx, wxis and the utilities built as ANSI (UTF8=0), with ISO-8859-1 data.
# Usage: bash smoke_test_ansi.sh dist/linux64/isis1660-ansi      (run it from the repository root)
# Tables used: tests/isisuctab_ansi.tab (accented letters -> unaccented upper case) and tests/isisactab_ansi.tab
set -u
export LC_ALL=POSIX
D=${1:-}
[ -x "$D/mx" ] && [ -x "$D/wxis" ] || { echo "usage: $0 <folder with the ANSI mx and wxis>   e.g. dist/linux64/isis1660-ansi"; exit 1; }
D=$(cd "$D" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
UC="$HERE/tests/isisuctab_ansi.tab"; AC="$HERE/tests/isisactab_ansi.tab"
[ -f "$UC" ] && [ -f "$AC" ] || { echo "ERROR: ANSI character tables missing in $HERE/tests"; exit 1; }
command -v iconv >/dev/null || { echo "ERROR: iconv not found"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
PASS=0; FAILN=0
ok()   { echo "  [ok]    $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL]  $1"; FAILN=$((FAILN+1)); }

B=$("$D/mx" 2>&1 | head -1)
case $B in *UTF-8*) fail "the banner says UTF-8: this is a UTF-8 build, use smoke_test.sh";; *) ok "banner without UTF-8 (ANSI build)";; esac

# data in ISO-8859-1 (1 byte per accented letter)
printf '%s\n' 'Água e Ação' 'ÁGUA' 'Ça va très bien' | iconv -f UTF-8 -t ISO-8859-1 > data.txt
printf '1 4 mpu,v1\n' > db.fst

"$D/mx" seq=data.txt create=db now -all >/dev/null 2>&1
"$D/mx" db "pft=v1/" now > back.txt 2>/dev/null
cmp -s data.txt back.txt && ok "mx: load and read back (identical round trip, ISO-8859-1 bytes)" || fail "mx: round trip differs"
N=$("$D/mx" db count=100 "pft=mfn/" now 2>/dev/null | wc -l)
[ "$N" = 3 ] && ok "mx: 3 records stored" || fail "mx: expected 3 records, found $N"

# indexing and searches with the ANSI tables (passed as mx options)
"$D/mx" db uctab="$UC" actab="$AC" "fst=@db.fst" fullinv=db now >/dev/null 2>&1
search() { # term in UTF-8 -> converted to ISO-8859-1 before searching
  Q=$(printf '%s' "$1" | iconv -f UTF-8 -t ISO-8859-1)
  "$D/mx" db uctab="$UC" actab="$AC" "bool=$Q" "pft=mfn/" now 2>/dev/null | grep -o 'Hits=[0-9]*' | cut -d= -f2; }
check() { R=$(search "$1"); [ "$R" = "$2" ] && ok "mx: search '$1' ($3) -> $R hit(s)" || fail "mx: search '$1' ($3): expected $2, got '${R:-?}'"; }
check 'ÁGUA'  2 "accented upper case"
check 'água'  2 "accented lower case finds ÁGUA/Água"
check 'AGUA'  2 "unaccented finds both"
check 'ça'    1 "cedilla"
check 'très'  1 "grave accent"
check 'AGU$'  2 "truncated"

tem() { [ -x "$D/$1" ]; }
if tem i2id && tem id2i; then
  "$D/i2id" db > a.id 2>/dev/null
  "$D/id2i" a.id create=db_id >/dev/null 2>&1
  "$D/mx" db_id "pft=v1/" now > back_id.txt 2>/dev/null
  cmp -s data.txt back_id.txt && ok "i2id + id2i: identical round trip" || fail "i2id + id2i: round trip differs"
fi
if tem crunchmf; then
  "$D/crunchmf" db db_cmf target=linux >/dev/null 2>&1
  "$D/mx" db_cmf "pft=v1/" now > back_cmf.txt 2>/dev/null
  cmp -s data.txt back_cmf.txt && ok "crunchmf target=linux: crunched database reads like the original" || fail "crunchmf target=linux: content differs"
fi
if tem crunchif && tem ifkeys; then
  cp db.mst db_cif.mst; cp db.xrf db_cif.xrf
  "$D/crunchif" db db_cif target=linux >/dev/null 2>&1
  N=$("$D/ifkeys" db_cif 2>/dev/null | wc -l)
  [ "$N" = 7 ] && ok "crunchif target=linux: crunched index with the 7 terms" || fail "crunchif target=linux: ifkeys lists $N terms (expected 7)"
fi
if tem retag; then
  cp db.mst db_rt.mst; cp db.xrf db_rt.xrf; printf '1 2\n' > retag.tab
  "$D/retag" db_rt retag.tab >/dev/null 2>&1
  V2=$("$D/mx" db_rt "pft=v2/" now 2>/dev/null); V1=$("$D/mx" db_rt "pft=v1/" now 2>/dev/null)
  cmp -s <(printf '%s' "$V2") <(printf '%s' "$(cat data.txt)") 2>/dev/null && [ -z "$V1" ] && ok "retag: field 1 became 2 without changing the text" || fail "retag: unexpected result"
fi
if tem ifkeys; then
  K=$("$D/ifkeys" db 2>/dev/null | sed 's/^ *[0-9]*|//' | tr '\n' ' ')
  [ "$K" = "ACAO AGUA BIEN CA E TRES VA " ] && ok "ifkeys: lists the 7 terms" || fail "ifkeys: unexpected list: $K"
fi

# wxis reads the database
cat > read.xis <<XIS
<IsisScript><section><do task=mfnrange><parm name=db>$T/db</parm><parm name=from>1</parm><parm name=to>3</parm><loop><display><pft>v1/</pft></display></loop></do></section></IsisScript>
XIS
"$D/wxis" IsisScript=read.xis > wxis_out.txt 2>/dev/null
cmp -s data.txt wxis_out.txt && ok "wxis: reads 3 records (identical to the original)" || fail "wxis: output differs"

# wxis writes by POST (as ABCD does with crear_registro.xis); the text is sent as ISO-8859-1 (%E7 = c-cedilla)
cat > write.xis <<XIS
<IsisScript><section>
<field action=cgi tag=9010>ValorCapturado</field>
<do task=update><parm name=db>$T/db</parm><parm name=mfn>New</parm>
<update><field action=define tag=1102>Isis_Status</field><field action=import tag=9010>9010</field>
<proc><pft>v9010</pft></proc><proc><pft>'d9010'</pft></proc><write>Unlock</write>
<display><pft>mfn</pft></display></update></do></section></IsisScript>
XIS
BODY="IsisScript=$T/write.xis&ValorCapturado=%3C1+0%3EA%E7%E3o+%2520+%C7a%3C%2F1%3E"
R=$(printf '%s' "$BODY" | REQUEST_METHOD=POST CONTENT_TYPE=application/x-www-form-urlencoded CONTENT_LENGTH=${#BODY} "$D/wxis" 2>/dev/null | tr -d '\n ')
V=$("$D/mx" db from=4 count=1 "pft=v1/" now 2>/dev/null | iconv -f ISO-8859-1 -t UTF-8)
[ "$((10#${R:-0}))" = 4 ] && [ "$V" = 'Ação %20 Ça' ] && ok "wxis: write via POST (accents, literal %20)" || fail "wxis: write via POST (mfn='$R', value='$V')"

echo "== $PASS ok, $FAILN failure(s)"
[ $FAILN = 0 ]
