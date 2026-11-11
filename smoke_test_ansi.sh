#!/usr/bin/env bash
# smoke_test_ansi.sh - teste rapido de mx, wxis e utilitarios compilados em ANSI (UTF8=0), dados ISO-8859-1.
# Uso: ./smoke_test_ansi.sh dist/linux64/ffi1660-ansi      (rode na raiz do repositorio)
# Tabelas usadas: tests/isisuctab_ansi.tab (acentos -> letra maiuscula sem acento) e tests/isisactab_ansi.tab
set -u
export LC_ALL=POSIX
D=${1:-}
[ -x "$D/mx" ] && [ -x "$D/wxis" ] || { echo "uso: $0 <pasta com mx e wxis ANSI>   ex.: dist/linux64/ffi1660-ansi"; exit 1; }
D=$(cd "$D" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
UC="$HERE/tests/isisuctab_ansi.tab"; AC="$HERE/tests/isisactab_ansi.tab"
[ -f "$UC" ] && [ -f "$AC" ] || { echo "ERRO: faltam as tabelas ANSI em $HERE/tests"; exit 1; }
command -v iconv >/dev/null || { echo "ERRO: iconv nao encontrado"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
PASS=0; FAILN=0
ok()   { echo "  [ok]    $1"; PASS=$((PASS+1)); }
fail() { echo "  [FALHA] $1"; FAILN=$((FAILN+1)); }

B=$("$D/mx" 2>&1 | head -1)
case $B in *UTF-8*) fail "o banner diz UTF-8: isto e um build UTF-8, use smoke_test.sh";; *) ok "banner sem UTF-8 (build ANSI)";; esac

# dados em ISO-8859-1 (1 byte por letra acentuada)
printf '%s\n' 'Água e Ação' 'ÁGUA' 'Ça va très bien' | iconv -f UTF-8 -t ISO-8859-1 > dados.txt
printf '1 4 mpu,v1\n' > db.fst

"$D/mx" seq=dados.txt create=db now -all >/dev/null 2>&1
"$D/mx" db "pft=v1/" now > volta.txt 2>/dev/null
cmp -s dados.txt volta.txt && ok "mx: carga e leitura (ida e volta identicas, bytes ISO-8859-1)" || fail "mx: ida e volta difere"
N=$("$D/mx" db count=100 "pft=mfn/" now 2>/dev/null | wc -l)
[ "$N" = 3 ] && ok "mx: 3 registros gravados" || fail "mx: esperava 3 registros, achou $N"

# indexacao e buscas com as tabelas ANSI (passadas como opcoes do mx)
"$D/mx" db uctab="$UC" actab="$AC" "fst=@db.fst" fullinv=db now >/dev/null 2>&1
busca() { # termo em UTF-8 -> convertido para ISO-8859-1 antes de buscar
  Q=$(printf '%s' "$1" | iconv -f UTF-8 -t ISO-8859-1)
  "$D/mx" db uctab="$UC" actab="$AC" "bool=$Q" "pft=mfn/" now 2>/dev/null | grep -o 'Hits=[0-9]*' | cut -d= -f2; }
check() { R=$(busca "$1"); [ "$R" = "$2" ] && ok "mx: busca '$1' ($3) -> $R resultado(s)" || fail "mx: busca '$1' ($3): esperado $2, obtido '${R:-?}'"; }
check 'ÁGUA'  2 "maiuscula acentuada"
check 'água'  2 "minuscula acentuada acha ÁGUA/Água"
check 'AGUA'  2 "sem acento acha as duas"
check 'ça'    1 "cedilha"
check 'très'  1 "acento grave"
check 'AGU$'  2 "truncado"

tem() { [ -x "$D/$1" ]; }
if tem i2id && tem id2i; then
  "$D/i2id" db > a.id 2>/dev/null
  "$D/id2i" a.id create=db_id >/dev/null 2>&1
  "$D/mx" db_id "pft=v1/" now > volta_id.txt 2>/dev/null
  cmp -s dados.txt volta_id.txt && ok "i2id + id2i: ida e volta identica" || fail "i2id + id2i: ida e volta difere"
fi
if tem crunchmf; then
  "$D/crunchmf" db db_cmf target=linux >/dev/null 2>&1
  "$D/mx" db_cmf "pft=v1/" now > volta_cmf.txt 2>/dev/null
  cmp -s dados.txt volta_cmf.txt && ok "crunchmf target=linux: base compactada le igual ao original" || fail "crunchmf target=linux: conteudo difere"
fi
if tem crunchif && tem ifkeys; then
  cp db.mst db_cif.mst; cp db.xrf db_cif.xrf
  "$D/crunchif" db db_cif target=linux >/dev/null 2>&1
  N=$("$D/ifkeys" db_cif 2>/dev/null | wc -l)
  [ "$N" = 7 ] && ok "crunchif target=linux: indice compactado com os 7 termos" || fail "crunchif target=linux: ifkeys lista $N termos (esperado 7)"
fi
if tem retag; then
  cp db.mst db_rt.mst; cp db.xrf db_rt.xrf; printf '1 2\n' > retag.tab
  "$D/retag" db_rt retag.tab >/dev/null 2>&1
  V2=$("$D/mx" db_rt "pft=v2/" now 2>/dev/null); V1=$("$D/mx" db_rt "pft=v1/" now 2>/dev/null)
  cmp -s <(printf '%s' "$V2") <(printf '%s' "$(cat dados.txt)") 2>/dev/null && [ -z "$V1" ] && ok "retag: campo 1 virou 2 sem alterar o texto" || fail "retag: resultado inesperado"
fi
if tem ifkeys; then
  K=$("$D/ifkeys" db 2>/dev/null | sed 's/^ *[0-9]*|//' | tr '\n' ' ')
  [ "$K" = "ACAO AGUA BIEN CA E TRES VA " ] && ok "ifkeys: lista os 7 termos" || fail "ifkeys: lista inesperada: $K"
fi

# wxis le a base
cat > le.xis <<XIS
<IsisScript><section><do task=mfnrange><parm name=db>$T/db</parm><parm name=from>1</parm><parm name=to>3</parm><loop><display><pft>v1/</pft></display></loop></do></section></IsisScript>
XIS
"$D/wxis" IsisScript=le.xis > wxis_out.txt 2>/dev/null
cmp -s dados.txt wxis_out.txt && ok "wxis: leitura de 3 registros (identica ao original)" || fail "wxis: saida difere"

# wxis grava por POST (como o ABCD faz com crear_registro.xis); o texto vai em ISO-8859-1 (%E7 = c-cedilha)
cat > grava.xis <<XIS
<IsisScript><section>
<field action=cgi tag=9010>ValorCapturado</field>
<do task=update><parm name=db>$T/db</parm><parm name=mfn>New</parm>
<update><field action=define tag=1102>Isis_Status</field><field action=import tag=9010>9010</field>
<proc><pft>v9010</pft></proc><proc><pft>'d9010'</pft></proc><write>Unlock</write>
<display><pft>mfn</pft></display></update></do></section></IsisScript>
XIS
BODY="IsisScript=$T/grava.xis&ValorCapturado=%3C1+0%3EA%E7%E3o+%2520+%C7a%3C%2F1%3E"
R=$(printf '%s' "$BODY" | REQUEST_METHOD=POST CONTENT_TYPE=application/x-www-form-urlencoded CONTENT_LENGTH=${#BODY} "$D/wxis" 2>/dev/null | tr -d '\n ')
V=$("$D/mx" db from=4 count=1 "pft=v1/" now 2>/dev/null | iconv -f ISO-8859-1 -t UTF-8)
[ "$((10#${R:-0}))" = 4 ] && [ "$V" = 'Ação %20 Ça' ] && ok "wxis: gravacao via POST (acentos, %20 literal)" || fail "wxis: gravacao via POST (mfn='$R', valor='$V')"

echo "== $PASS ok, $FAILN falha(s)"
[ $FAILN = 0 ]
