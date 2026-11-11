#!/usr/bin/env bash
# smoke_test.sh - teste rapido de mx e wxis em UTF-8 (acentos, russo, hebraico).
# Uso: ./smoke_test.sh dist/linux32/ffi1660        (rode na raiz do repositorio)
# As tabelas de caracteres usadas estao em tests/ (actab com letras hebraicas acrescentadas).
set -u
export LC_ALL=POSIX
D=${1:-}
[ -x "$D/mx" ] && [ -x "$D/wxis" ] || { echo "uso: $0 <pasta com mx e wxis>   ex.: dist/linux32/ffi1660"; exit 1; }
D=$(cd "$D" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
TAB="$HERE/tests"
[ -f "$TAB/isisuctab_utf8.tab" ] && [ -f "$TAB/isisactab_utf8_he.tab" ] || { echo "ERRO: faltam as tabelas em $TAB"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
PASS=0; FAILN=0
ok()   { echo "  [ok]    $1"; PASS=$((PASS+1)); }
fail() { echo "  [FALHA] $1"; FAILN=$((FAILN+1)); }

printf '%s\n' 'Água e Ação' 'ÁGUA' 'Привет мир' 'שלום עולם' 'Ça va très bien' > dados.txt
printf 'uctab=%s\nactab=%s\n' "$TAB/isisuctab_utf8.tab" "$TAB/isisactab_utf8_he.tab" > t.par
printf '1 4 mpu,v1\n' > db.fst

# 1) carga e leitura de volta (ida e volta byte a byte)
"$D/mx" seq=dados.txt create=db now -all >/dev/null 2>&1
"$D/mx" db "pft=v1/" now > volta.txt 2>/dev/null
cmp -s dados.txt volta.txt && ok "mx: carga e leitura (ida e volta identicas)" || fail "mx: ida e volta difere"
N=$("$D/mx" db count=100 "pft=mfn/" now 2>/dev/null | wc -l)
[ "$N" = 5 ] && ok "mx: 5 registros gravados" || fail "mx: esperava 5 registros, achou $N"

# 2) indexacao com as tabelas UTF-8 lidas do .par e buscas
"$D/mx" cipar=t.par db "fst=@db.fst" fullinv=db now >/dev/null 2>&1
busca() { "$D/mx" cipar=t.par db "bool=$1" "pft=mfn/" now 2>/dev/null | grep -o 'Hits=[0-9]*' | cut -d= -f2; }
check() { # termo, esperado, rotulo
  R=$(busca "$1"); [ "$R" = "$2" ] && ok "mx: busca '$1' ($3) -> $R resultado(s)" || fail "mx: busca '$1' ($3): esperado $2, obtido '${R:-?}'"; }
check 'ÁGUA'    2 "maiuscula acentuada"
check 'água'    2 "minuscula acentuada acha ÁGUA/Água"
check 'ça'      1 "cedilha"
check 'привет'  1 "russo"
check 'ПРИВЕТ'  1 "russo, caixa alta"
check 'שלום'    1 "hebraico"
check 'עולם'    1 "hebraico"

# 2b) busca com truncamento ($): percorre o dicionario em sequencia (usa o terminador highv)
check 'ПРИВ$'  1 "russo, truncado"
check 'שלו$'    1 "hebraico, truncado"
check 'AGU$'    2 "latim, truncado"

# 2c) utilitarios usados pelo ABCD (so testa os que existem na pasta)
tem() { [ -x "$D/$1" ]; }
if tem i2id && tem id2i; then
  "$D/i2id" db > a.id 2>/dev/null
  "$D/id2i" a.id create=db_id >/dev/null 2>&1
  "$D/mx" db_id "pft=v1/" now > volta_id.txt 2>/dev/null
  cmp -s dados.txt volta_id.txt && grep -q 'שלום עולם' a.id && ok "i2id + id2i: ida e volta UTF-8 identica" || fail "i2id + id2i: ida e volta difere"
fi
if tem crunchmf; then
  # sem target, o crunchmf converte para o formato da OUTRA plataforma (e o que db_convert_crunchmf.php do ABCD usa)
  "$D/crunchmf" db db_cmf_pc >/dev/null 2>&1
  [ -s db_cmf_pc.mst ] && [ -s db_cmf_pc.xrf ] && ok "crunchmf: destino padrao (outra plataforma) gera .mst/.xrf" || fail "crunchmf: destino padrao nao gerou arquivos"
  "$D/crunchmf" db db_cmf target=linux >/dev/null 2>&1
  "$D/mx" db_cmf "pft=v1/" now > volta_cmf.txt 2>/dev/null
  cmp -s dados.txt volta_cmf.txt && ok "crunchmf target=linux: base compactada le igual ao original" || fail "crunchmf target=linux: conteudo difere"
fi
if tem crunchif && tem ifkeys; then
  cp db.mst db_cif.mst; cp db.xrf db_cif.xrf
  "$D/crunchif" db db_cif target=linux >/dev/null 2>&1
  N=$("$D/ifkeys" db_cif 2>/dev/null | wc -l)
  [ "$N" = 11 ] && ok "crunchif target=linux: indice compactado com os 11 termos" || fail "crunchif target=linux: ifkeys lista $N termos (esperado 11)"
fi
if tem retag; then
  cp db.mst db_rt.mst; cp db.xrf db_rt.xrf; printf '1 2\n' > retag.tab
  "$D/retag" db_rt retag.tab >/dev/null 2>&1
  V2=$("$D/mx" db_rt "pft=v2/" now 2>/dev/null); V1=$("$D/mx" db_rt "pft=v1/" now 2>/dev/null)
  cmp -s <(printf '%s' "$V2") <(printf '%s' "$(cat dados.txt)") 2>/dev/null && [ -z "$V1" ] && ok "retag: campo 1 virou 2 sem alterar o texto UTF-8" || fail "retag: resultado inesperado"
fi
if tem ifkeys; then
  K=$("$D/ifkeys" db 2>/dev/null | sed 's/^ *[0-9]*|//' | tr '\n' ' ')
  [ "$K" = "ACAO AGUA BIEN CA E TRES VA МИР ПРИВЕТ עולם שלום " ] && ok "ifkeys: lista os 11 termos (latim, russo, hebraico)" || fail "ifkeys: lista incompleta: $K"
  K2=$("$D/ifkeys" db from=ПРИВЕТ 2>&1 | sed 's/^ *[0-9]*|//' | tr '\n' ' ')
  [ "$K2" = "ПРИВЕТ עולם שלום " ] && ok "ifkeys from=ПРИВЕТ: sem travar e com os termos seguintes" || fail "ifkeys from=: '$K2'"
fi

# 3) wxis le a base e devolve o mesmo texto
cat > le.xis <<XIS
<IsisScript><section><do task=mfnrange><parm name=db>$T/db</parm><parm name=from>1</parm><parm name=to>5</parm><loop><display><pft>v1/</pft></display></loop></do></section></IsisScript>
XIS
"$D/wxis" IsisScript=le.xis > wxis_out.txt 2>/dev/null
cmp -s dados.txt wxis_out.txt && ok "wxis: leitura de 5 registros (identica ao original)" || fail "wxis: saida difere"

# 4) wxis grava um registro novo recebido por POST (como o ABCD faz com crear_registro.xis)
cat > grava.xis <<XIS
<IsisScript><section>
<field action=cgi tag=9010>ValorCapturado</field>
<do task=update><parm name=db>$T/db</parm><parm name=mfn>New</parm>
<update><field action=define tag=1102>Isis_Status</field><field action=import tag=9010>9010</field>
<proc><pft>v9010</pft></proc><proc><pft>'d9010'</pft></proc><write>Unlock</write>
<display><pft>mfn</pft></display></update></do></section></IsisScript>
XIS
BODY="IsisScript=$T/grava.xis&ValorCapturado=%3C1+0%3ENova+a%C3%A7%C3%A3o+%D7%A9%D7%9C%D7%95%D7%9D+%2520+%C3%87a%3C%2F1%3E"
R=$(printf '%s' "$BODY" | REQUEST_METHOD=POST CONTENT_TYPE=application/x-www-form-urlencoded CONTENT_LENGTH=${#BODY} "$D/wxis" 2>/dev/null | tr -d '\n ')
V=$("$D/mx" db from=6 count=1 "pft=v1/" now 2>/dev/null)
[ "$((10#${R:-0}))" = 6 ] && [ "$V" = 'Nova ação שלום %20 Ça' ] && ok "wxis: gravacao via POST (acentos, hebraico, %20 literal)" || fail "wxis: gravacao via POST (mfn='$R', valor='$V')"

echo "== $PASS ok, $FAILN falha(s)"
[ $FAILN = 0 ]
