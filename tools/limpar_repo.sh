#!/usr/bin/env bash
# limpar_repo.sh - tira do repositorio o que NAO e necessario para compilar os programas do ABCD.
#
# Uso (na raiz do repositorio):
#   tools/limpar_repo.sh              simulacao: so mostra o que seria feito (nao altera nada)
#   tools/limpar_repo.sh --aplicar    aplica com git rm / git mv (historico preservado)
#
# O que faz:
#   MANTEM   arquivos do nucleo (fontes, cabecalhos e .mak dos programas do ABCD + wxis) e o kit de compilacao
#   APAGA    binarios, saidas de IDE, e arquivos identicos aos do original da BIREME (recuperaveis de la)
#   MOVE     para legacy/ o que e so deste repositorio ou difere da BIREME (scripts antigos, .mak dos outros programas)
# Antes de aplicar cria a tag pre-limpeza-AAAAMMDD: "git checkout <tag>" volta a ter tudo.
# As listas abaixo foram calculadas sobre o commit 1243af2 (compilando so com o "nucleo" e passando nos testes).
set -u
cd "$(dirname "$0")/.." || exit 1
[ -f cisis.h ] || { echo "ERRO: rode na raiz do repositorio (onde esta o cisis.h)"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERRO: isto nao e um repositorio git"; exit 1; }
APLICAR=0; [ "${1:-}" = "--aplicar" ] && APLICAR=1

read -r -d '' KEEP <<'LISTA_KEEP'
.gitattributes
.gitignore
COMPILING.md
LICENSE
README.md
build_linux.sh
build_windows_bcc55.bat
build_windows_tools_bcc55.bat
cib70.h
cib71.c
cib72.c
cicgi.c
cidbx.c
cifm1.c
cifm2.c
cifm3.c
cifmt.h
cifst.c
cigiz.c
cihsh.c
cihsh.h
ciifl.c
ciiflh.c
ciifu.c
ciifu2.c
ciifuh.c
ciiso.c
cirec.c
cirun.h
cisis.h
cisisx.c
citrm.c
ciupd.c
ciupdclps.c
ciupddeco.c
ciupddump.c
ciupdload.c
ciupdmark.c
ciupdmarx.c
ciupdserx.c
ciupdserxpc.c
ciupdsock.c
ciupdsocx.c
ciupdsocxpc.c
ciupdsocy.c
ciupdsplt.c
ciupg.c
ciupi.c
ciupi.h
ciutf8.c
ciutf8.h
ciutl.c
crunchif.c
crunchif.mak
crunchmf.c
crunchmf.mak
easyfc.c
find_compilers.ps1
i2id.c
i2id.mak
id2i.c
id2i.mak
ifkeys.c
ifkeys.mak
ifload.c
ifload.mak
ifloadao.c
ifp1.c
ifp1.mak
ifupd.c
ifupd.mak
lydump.c
lydump.mak
lyfreq.c
lyfreq.mak
mdl2i.c
mdl2i.mak
mdl2ir.c
mdl2ir.mak
mdlif.c
mdlif.mak
mdlmf.c
mdlmf.mak
mdlup.c
mdlup.mak
mkiy0.c
mkiy0.mak
mkxrf.c
mkxrf.mak
msrt.c
msrt.mak
mx.c
mx.h
mx.mak
mxaot.c
mxbol.c
mxcp.c
mxcp.mak
mxf0.c
mxf0.mak
mxfun.c
mxfun.h
mxget.c
mxget.mak
mxgw.c
mxgw.mak
mxmys.mak
mxrel.c
mxrun.c
mxrun.h
mxtb.c
mxtb.mak
mxtxt.c
mys.c
mys.mak
myz.c
myz.mak
myzcru.c
myzcru.mak
mz.c
mz.mak
retag.c
retag.mak
rule.c
rule.mak
serw.c
serw.mak
serw2.c
serw2.mak
serx.c
serx.mak
sizeof.c
sizeof.mak
sizeof2.c
sizeof2.mak
smoke_test.sh
smoke_test_ansi.sh
splitem.c
splitem.mak
splitm.c
splitm.mak
w2.c
w21.c
w2arg.c
w2ci.c
w2ctv.c
w2djk.c
w2djv.c
w2iscms.c
w2loc.c
w2oid.c
w2ojd.c
w2out1.c
w2outx.c
w2ov3.c
w2p0.c
w2pcol.c
w2pcox.c
w2pdoc.c
w2ralbs.c
w2rcol.c
w2rdoc.c
w2rel1.c
w2rhit.c
w2rtphix.c
w2set.c
w2setrt.c
w2simil.c
w2slng.c
w2tkey.c
w2tksum.c
w2top.c
wt.h
wtfun.c
wtfun.h
wtrun.c
wtrun.h
wtrunz.h
wtz.h
wxis.mak
wxis_src/arglist.c
wxis_src/arglist.h
wxis_src/cgilist.c
wxis_src/cgilist.h
wxis_src/chronometer.c
wxis_src/chronometer.h
wxis_src/cimsrt.c
wxis_src/cimsrt.h
wxis_src/citpv.c
wxis_src/citpv.h
wxis_src/cixml.c
wxis_src/cixml.h
wxis_src/easyci.c
wxis_src/easyci.h
wxis_src/easyfc.c
wxis_src/easyfc.h
wxis_src/easyfc2.h
wxis_src/freqlist.c
wxis_src/freqlist.h
wxis_src/hide.c
wxis_src/hide.h
wxis_src/hlfill.c
wxis_src/hlfill.h
wxis_src/xis.c
wxis_src/xis_comp.c
wxis_src/xis_comp.h
wxis_src/xis_exec.c
wxis_src/xis_exec.h
wxis_src/xis_server.h
LISTA_KEEP

read -r -d '' APAGAR <<'LISTA_APAGAR'
1660utf8/app0
1660utf8/asael1
1660utf8/crunchif
1660utf8/crunchmf
1660utf8/ctlmfn
1660utf8/dx0
1660utf8/i2id
1660utf8/id2i
1660utf8/ifkeys
1660utf8/ifload
1660utf8/ifmerge
1660utf8/lydump
1660utf8/lyfreq
1660utf8/mdl2i
1660utf8/mdl2ir
1660utf8/mdlif
1660utf8/mdlup
1660utf8/mkiy0
1660utf8/mkxrf
1660utf8/msrt
1660utf8/mx
1660utf8/mxcp
1660utf8/mxf0
1660utf8/mxmys
1660utf8/mys
1660utf8/myz
1660utf8/retag
1660utf8/rule
1660utf8/serw
1660utf8/serw2
1660utf8/serx
1660utf8/sizeof
1660utf8/sizeof2
1660utf8/splitem
1660utf8/wxis
LE2srch
a1.c
aix.c
alloc.h
aotcie1.c
aotmsa1.c
aotmsa12.c
aotmsa2.c
aotmsa244a.c
aotmsa2mfn.c
aotmsa2pc.c
aotmsa2x3.c
aotmsa3.c
app0.c
appeasy.h
asael1.c
b6x.c
b7.c
b7aot.c
b7x.c
bcc_test.c
buffet.c
c1.c
c2.c
cat.c
cat0.c
chkterm.c
ciapi.h
cib60.cpp
cib60.hpp
cib7.cpp
cib7.hpp
cibx.hpp
cicgi.cpp
cicgi.hpp
cidbx.cpp
cidbx.hpp
cidump.c
cienv.c
cienv.h
cifm3_unicode.c
cifmt.cpp
cifmt.hpp
cifst.cpp
cifst.hpp
ciifl.cpp
ciifl.hpp
ciifu.cpp
ciifu.hpp
ciiso.cpp
ciiso.hpp
cirec.cpp
cirec.hpp
cirun.hpp
cisis.h.save
cisis.h.save.1
cisisx.cpp
cisisx.hpp
citrm.cpp
citrm.hpp
ciupdxslt.c
ciupi.cpp
ciutf8.c2
ciutl.cpp
client1.c
client2.c
client3.c
client30.c
client4.c
configuracoes.txt
ctlmfn.c
decs9a.c
decs9b.c
decsex.c
decsmesh.c
dx0.c
err.out
fcm.c
fcx.c
fixi80.c
fxl0.c
gcc_test.c
generateAll32.sh
generateApp32.sh
generateApp64.sh
genqlf.c
globdef.h
ifkeys
iflind.c
ifmerge.c
listenv.c
main.c
main.o
makemake32.xsh
makemake64.xsh
makemakeApp32.xsh
makemakeApp64.xsh
mkffiG4_4_64.xsh
mx.DSW
mx.csm
mx.ilc
mx.ild
mx.ilf
mx.ils
mx.mbt
mx.mrt
mx.pft
mx64.mak0
mxget1.c
mxmake32.xsh
mxmake64.xsh
mxnew.pft
p1.c
p1x.c
p6a.c
p6b.c
p6b4.c
p7b.c
r1.c
rec1.c
serc.c
serw2a.c
serwofi.c
serwpc.c
serx1.c
serx2.c
serx3.c
soc1.c
t1.c
ticds.cnt
ticds.iyp
ticds.n01
ticds.n02
twtgo.c
w2djk-up.c
wheredef.h
wtrig1.c
wtrig2.c
wxis.DSW
wxis.exe
wxis.ilc
wxis.ild
wxis.ilf
wxis.ils
wxis.mbt
wxis.mrt
wxis_src/alloc.h
wxis_src/chronometer.php
wxis_src/easyfc(1).c
wxis_src/easyfc.c.57e
wxis_src/easyfc.c.57e.eds
wxis_src/easyfc.c.aot
wxis_src/examples/SCRIPT1.XIS
wxis_src/examples/Split.xis
wxis_src/examples/append.xis
wxis_src/examples/call.xis
wxis_src/examples/cds/cds.fdt
wxis_src/examples/cds/cds.fst
wxis_src/examples/cds/cds.iso
wxis_src/examples/cds/cds.pft
wxis_src/examples/cds/cds.stw
wxis_src/examples/cds/export2.xis
wxis_src/examples/cds/fullinv.xis
wxis_src/examples/cds/import2.xis
wxis_src/examples/cds/import3.xis
wxis_src/examples/cds/mfnrange2.xis
wxis_src/examples/cds/search.xis
wxis_src/examples/cds/search_chico.xis
wxis_src/examples/cdsx/cds.cnt
wxis_src/examples/cdsx/cds.fdt
wxis_src/examples/cdsx/cds.fst
wxis_src/examples/cdsx/cds.iso
wxis_src/examples/cdsx/cds.iyp
wxis_src/examples/cdsx/cds.ly1
wxis_src/examples/cdsx/cds.ly2
wxis_src/examples/cdsx/cds.mst
wxis_src/examples/cdsx/cds.n01
wxis_src/examples/cdsx/cds.n02
wxis_src/examples/cdsx/cds.pft
wxis_src/examples/cdsx/cds.stw
wxis_src/examples/cdsx/cds.xrf
wxis_src/examples/cdsx/export2.xis
wxis_src/examples/cdsx/fullinv.xis
wxis_src/examples/cdsx/import2.xis
wxis_src/examples/cdsx/import3.xis
wxis_src/examples/cdsx/mfnrange2.xis
wxis_src/examples/cdsx/search.xis
wxis_src/examples/cdsx/search_chico.xis
wxis_src/examples/cgiopt.xis
wxis_src/examples/cgitable.xis
wxis_src/examples/cipar.xis
wxis_src/examples/copiaRegistro.xis
wxis_src/examples/copy.xis
wxis_src/examples/copy2.xis
wxis_src/examples/copy3.xis
wxis_src/examples/copyfile.xis
wxis_src/examples/createdb.xis
wxis_src/examples/date.xis
wxis_src/examples/define.xis
wxis_src/examples/delfile.xis
wxis_src/examples/deltest.xis
wxis_src/examples/entity.xis
wxis_src/examples/err.xis
wxis_src/examples/erro1.xis
wxis_src/examples/export.xis
wxis_src/examples/export2.xis
wxis_src/examples/expr.xis
wxis_src/examples/expr0.xis
wxis_src/examples/extract.xis
wxis_src/examples/fi2.xis
wxis_src/examples/fieldimp.xis
wxis_src/examples/fieldocc.xis
wxis_src/examples/firstl.xis
wxis_src/examples/flddir.xis
wxis_src/examples/fldexpp.xis
wxis_src/examples/fmtbug.xis
wxis_src/examples/format.xis
wxis_src/examples/freq.xis
wxis_src/examples/fst.xis
wxis_src/examples/fullinv.xis
wxis_src/examples/function.xis
wxis_src/examples/genstw.xis
wxis_src/examples/getenv.xis
wxis_src/examples/hello.xis
wxis_src/examples/html2pft.xis
wxis_src/examples/htmlpft.xis
wxis_src/examples/implist.xis
wxis_src/examples/import.xis
wxis_src/examples/import2.xis
wxis_src/examples/incl1.xis
wxis_src/examples/incl2.xis
wxis_src/examples/incl3.xis
wxis_src/examples/incl4.xis
wxis_src/examples/incl5.xis
wxis_src/examples/include_1.xis
wxis_src/examples/inv3step.xis
wxis_src/examples/inv_e.xis
wxis_src/examples/inv_l.xis
wxis_src/examples/inv_s.xis
wxis_src/examples/keyrange.xis
wxis_src/examples/keyrpost.xis
wxis_src/examples/list.xis
wxis_src/examples/list2.xis
wxis_src/examples/mastersort.xis
wxis_src/examples/mfnrange.xis
wxis_src/examples/mfnrange2.xis
wxis_src/examples/mfnrmfnr.xis
wxis_src/examples/outapp.xis
wxis_src/examples/output.xis
wxis_src/examples/peru.xis
wxis_src/examples/peru1.xis
wxis_src/examples/peru2.xis
wxis_src/examples/pftpft.xis
wxis_src/examples/plus.xis
wxis_src/examples/putenv.xis
wxis_src/examples/recstat.xis
wxis_src/examples/rel50.xis
wxis_src/examples/search.xis
wxis_src/examples/search2.xis
wxis_src/examples/searchb7.xis
wxis_src/examples/searchhl.xis
wxis_src/examples/searchpf.xis
wxis_src/examples/sort.xis
wxis_src/examples/spaces.xis
wxis_src/examples/status.xis
wxis_src/examples/task.xis
wxis_src/examples/tempfile.xis
wxis_src/examples/teste.xis
wxis_src/examples/teste1.xis
wxis_src/examples/trim.xis
wxis_src/examples/unlock.xis
wxis_src/examples/update.xis
wxis_src/examples/x.xis
wxis_src/examples/xml.xis
wxis_src/examples/xml1.xis
wxis_src/xis_exec.bak
wxis_src/xis_server.c
xls
LISTA_APAGAR

read -r -d '' LEGACY <<'LISTA_LEGACY'
aotmsa2.mak
appeasy.c
b7.mak
bcc32.cfg
changes.txt
chkterm.mak
cifm3_standard.c
compile_wxis.sh
decs9a.mak
decs9b.mak
decsex.mak
fxl0.mak
generateAll32.bat
generateAll322.sh
generateAll64.sh
generateAll642.sh
ifmerge.mak
ilink32.cfg
makemake642.bat
makemake642.xsh
makemakeApp322.xsh
makemakeApp642.xsh
makemx.bat
makemz.sh
makewxis.bat
mkBigIsis.xsh
mkBigIsis_64.xsh
mkffi.xsh
mkffi1660.xsh
mkffi1660_64.xsh
mkffi512.xsh
mkffi512G4.xsh
mkffi512G4_64.xsh
mkffi512_64.xsh
mkffiG4.xsh
mkffiG4_4.xsh
mkffiG4_64.xsh
mkffi_64.xsh
mkisis.xsh
mkisis1660.xsh
mkisis1660_64.xsh
mkisis1660_642.xsh
mkisisG.xsh
mkisisG_64.xsh
mkisis_64.xsh
mklind.xsh
mklind512.xsh
mklind512G4.xsh
mklind512G4_64.xsh
mklind512_64.xsh
mklindG4.xsh
mklindG4_64.xsh
mklind_64.xsh
stdio.h
wtrig1.mak
wtrig2.mak
wxis_src/examples/list3.xis
wxis_src/examples/xis_exec.c
xmk.xsh
LISTA_LEGACY

# trava de seguranca: nada que o nucleo usa pode estar nas listas de saida
conflito=$( { printf '%s\n' "$APAGAR"; printf '%s\n' "$LEGACY"; } | sort | comm -12 - <(printf '%s\n' "$KEEP" | sort) )
[ -z "$conflito" ] || { echo "ERRO: arquivos do nucleo nas listas de saida:"; echo "$conflito"; exit 1; }

destino() { # caminho -> pasta em legacy/
  case "$1" in
    *.xsh|*.sh|*.bat|*.cfg|*.mak0) echo "legacy/scripts/$1";;
    *.mak)                         echo "legacy/mak/$1";;
    *)                             echo "legacy/fontes/$1";;
  esac; }

nap=0; nle=0; nfalta=0
while IFS= read -r p; do [ -n "$p" ] || continue; if git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then nap=$((nap+1)); else nfalta=$((nfalta+1)); fi; done <<< "$APAGAR"
while IFS= read -r p; do [ -n "$p" ] || continue; if git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then nle=$((nle+1)); else nfalta=$((nfalta+1)); fi; done <<< "$LEGACY"

# arquivos rastreados que nao estao em nenhuma lista (novos desde a analise): nao sao tocados
nao_tocados=$(git ls-files | sort | comm -23 - <( { printf '%s\n' "$KEEP"; printf '%s\n' "$APAGAR"; printf '%s\n' "$LEGACY"; } | sort ) | grep -v -E '^(tests/|tools/|legacy/)' )

echo "== limpar_repo: apagar=$nap  mover para legacy/=$nle  (ja ausentes: $nfalta)"
if [ -n "$nao_tocados" ]; then echo "== rastreados que NAO estao em nenhuma lista (serao mantidos; confira):"; echo "$nao_tocados" | sed 's/^/     /'; fi

if [ $APLICAR = 0 ]; then
  echo "== SIMULACAO. Nada foi alterado. Para aplicar:  tools/limpar_repo.sh --aplicar"
  echo "   Exemplos do que sera apagado:"; printf '%s\n' "$APAGAR" | head -6 | sed 's/^/     - /'
  echo "   Exemplos do que vai para legacy/:"; printf '%s\n' "$LEGACY" | head -4 | while IFS= read -r p; do echo "     > $p  ->  $(destino "$p")"; done
  exit 0
fi

git diff --quiet && git diff --cached --quiet || { echo "ERRO: ha alteracoes nao salvas em arquivos rastreados. Faca commit antes (a limpeza fica num commit proprio e reversivel)."; exit 1; }
TAG="pre-limpeza-$(date +%Y%m%d)"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || git tag "$TAG" || { echo "ERRO: nao consegui criar a tag $TAG"; exit 1; }
echo "== tag de seguranca: $TAG   (volta com: git checkout $TAG)"

while IFS= read -r p; do [ -n "$p" ] || continue; git ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && git rm -q -- "$p"; done <<< "$APAGAR"
while IFS= read -r p; do
  [ -n "$p" ] || continue
  git ls-files --error-unmatch -- "$p" >/dev/null 2>&1 || continue
  d=$(destino "$p"); mkdir -p "$(dirname "$d")"; git mv -- "$p" "$d"
done <<< "$LEGACY"

cat > legacy/LEIA-ME.md <<'LEIAME'
# legacy/

Arquivos que **nao** sao necessarios para compilar os programas do ABCD, mas que diferem do original da BIREME
ou existiam so neste repositorio. Ficam aqui para consulta; nada daqui entra na compilacao.

- `scripts/`  scripts antigos de geracao (`makemake*.xsh`, `mk*.xsh`, `generateAll*`, `.bat`, `.cfg` do Borland). Substituidos por `build_linux.sh` e `build_windows_*.bat`.
- `mak/`      `.mak` de programas da BIREME que o ABCD nao usa (aotmsa2, b7, chkterm, decs9a/b, decsex, fxl0, ifmerge, wtrig1/2), ja com `ciutf8.o`.
- `fontes/`   fontes alterados ou so deste repositorio (`cifm3_standard.c`, `appeasy.c`, `changes.txt` da arvore 5.7e, `stdio.h` do Borland, exemplos).

O restante do codigo da BIREME (outros programas, versao C++, exemplos do wxis) foi removido por ser identico ao original:
https://github.com/bireme/cisis   (tambem na tag `pre-limpeza-*` deste repositorio).
LEIAME
git add legacy/LEIA-ME.md
echo "== pronto. Confira com: git status --short | head ; depois compile:  ./build_linux.sh -a 64 -t all  e  ./smoke_test.sh dist/linux64/ffi1660"
