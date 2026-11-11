#!/usr/bin/env bash
# build_linux.sh - compila o CISIS (mx, wxis, ...) no Linux a partir da raiz do repositorio.
#
# Uso:  ./build_linux.sh [-a 32|64] [-v VARIANTE] [-t "alvos"] [-u 0|1] [-j N] [-c]
#   -a  arquitetura: 32 (padrao, mais seguro) ou 64 (ver COMPILING.md)
#   -v  variante:    ffi1660 (padrao, ABCD) | bigisis | isis1660 | isis
#   -t  alvos (arquivos .mak sem a extensao). Padrao: "mx wxis".  "all" = todos os .mak
#   -u  UTF-8: 1 (padrao) ou 0 (build ANSI; saida em dist/.../<variante>-ansi)
#   -x  INCLOADX: 1 = le uctab=/actab= do arquivo .par; 0 = ignora. Padrao: igual a -u (ANSI oficial da BIREME ignora)
#   -j  processos paralelos (padrao: nproc)
#   -s  compila com char COM SINAL (como o Borland C++ 5.5 dos .exe oficiais); padrao: -funsigned-char
#   -c  apaga build/ e dist/ antes de compilar
#
# Saida: dist/linux<arch>/<variante>/<alvo>   (logs em build/<arch>-<variante>/logs)
# Os objetos (.o) ficam em build/, o repositorio nao e sujado.

set -u
export LC_ALL=POSIX

ARCH=32; VARIANT=ffi1660; TARGETS="mx wxis"; UTF8=1; JOBS=$(nproc 2>/dev/null || echo 2); CLEAN=0; SIGNED=0; INCX=""
while getopts "a:v:t:u:x:j:csh" o; do
  case $o in
    a) ARCH=$OPTARG;; v) VARIANT=$OPTARG;; t) TARGETS=$OPTARG;; u) UTF8=$OPTARG;; x) INCX=$OPTARG;; j) JOBS=$OPTARG;; c) CLEAN=1;; s) SIGNED=1;;
    *) sed -n '2,15p' "$0"; exit 1;;
  esac
done

ROOT=$(cd "$(dirname "$0")" && pwd)
[ -f "$ROOT/cisis.h" ] || { echo "ERRO: rode este script na raiz do repositorio (onde esta o cisis.h)"; exit 1; }
command -v gcc  >/dev/null || { echo "ERRO: gcc nao encontrado (sudo apt install build-essential)"; exit 1; }
command -v make >/dev/null || { echo "ERRO: make nao encontrado (sudo apt install build-essential)"; exit 1; }

# ---- variantes (iguais as de makemake64.xsh / generateAll*.sh) ----
case $VARIANT in
  isis)      V="CIFFI=0 LIND=0 LIND4=0 ISISXL=0 ISISXL512=0 SUPERISIS=0 _FILE_OFFSET_BITS=00 _LARGEFILE64_SOURCE=0";;
  isis1660)  V="CIFFI=0 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0 SUPERISIS=0 _FILE_OFFSET_BITS=00 _LARGEFILE64_SOURCE=0";;
  ffi1660)   V="CIFFI=1 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0 SUPERISIS=0 _FILE_OFFSET_BITS=00 _LARGEFILE64_SOURCE=0";;
  bigisis)   V="CIFFI=1 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0 SUPERISIS=1 _FILE_OFFSET_BITS=64 _LARGEFILE64_SOURCE=1";;
  *) echo "ERRO: variante desconhecida: $VARIANT"; exit 1;;
esac

# ---- arquitetura ----
case $ARCH in
  32) CC="gcc -m32";             V="$V SIXTY_FOUR=0"
      echo 'int main(void){return 0;}' > /tmp/_cisis_t.c
      gcc -m32 /tmp/_cisis_t.c -o /tmp/_cisis_t32 2>/dev/null && /tmp/_cisis_t32 || {
        echo "ERRO: gcc -m32 nao funciona. Instale:  sudo apt install gcc-multilib libc6-i386"; exit 1; };;
  64) CC="gcc -no-pie -fno-pie"; V="$V SIXTY_FOUR=1"
      # Sem os campos CIPTR (ponteiros do compilador de formatos guardados em int), so funciona nao-PIE.
      # Com o patch aplicado (cisis.h define CIPTR) o executavel PIE padrao e seguro.
      if grep -q "CIPTR" "$ROOT/cisis.h"; then CC="gcc"; else CC="gcc -no-pie -fno-pie"; echo "AVISO: cisis.h sem CIPTR: gerando 64 bits nao-PIE (frágil)"; fi
      ;;
  *) echo "ERRO: -a deve ser 32 ou 64"; exit 1;;
esac
CCFLAGS="-funsigned-char -Wall -DUTF8=$UTF8"
[ $SIGNED = 1 ] && CCFLAGS="-fsigned-char -Wall -DUTF8=$UTF8"
# INCLOADX=1: sem isso o CISIS ignora uctab=/actab= do arquivo .par e nao indexa/pesquisa
# palavras fora do latim basico (russo, grego, hebraico...). Veja COMPILING.md.
[ -z "$INCX" ] && INCX=$UTF8        # padrao: ligado em UTF-8, desligado em ANSI (igual aos binarios oficiais da BIREME)
[ "$INCX" = 1 ] && CCFLAGS="$CCFLAGS -DINCLOADX=1"

if [ "$TARGETS" = "all" ]; then
  TARGETS=$(cd "$ROOT" && ls *.mak | sed 's/\.mak$//' | tr '\n' ' ')
  # mxgw e mz ainda usam as tabelas ANSI direto (isiswctab) e nao foram portados para UTF-8:
  # em "all" so sao compilados no modo ANSI (-u 0). Com -t explicito o script tenta mesmo assim.
  if [ "$UTF8" = 1 ]; then TARGETS=$(for t in $TARGETS; do case $t in mxgw|mz) echo "AVISO: $t pulado em UTF-8 (porte pendente; use -u 0)" >&2;; *) printf '%s ' $t;; esac; done); fi
fi

SUF=""; [ $SIGNED = 1 ] && SUF="-signed"
[ "$UTF8" = 0 ] && SUF="$SUF-ansi"   # build ANSI vai para outra pasta: dist/linux64/ffi1660-ansi
[ "$UTF8" = 0 ] && [ "$INCX" = 1 ] && SUF="$SUF-par"   # ANSI lendo uctab=/actab= do .par: dist/.../ffi1660-ansi-par
BUILD="$ROOT/build/$ARCH-$VARIANT$SUF"; WORK="$BUILD/work"; LOGS="$BUILD/logs"
DIST="$ROOT/dist/linux$ARCH/$VARIANT$SUF"
[ $CLEAN = 1 ] && rm -rf "$ROOT/build" "$ROOT/dist"
mkdir -p "$WORK" "$LOGS" "$DIST"

# copia de trabalho (objetos fora da arvore de fontes); .mak convertidos para LF
rm -rf "$WORK"; mkdir -p "$WORK"
(cd "$ROOT" && cp -- *.c *.h *.mak "$WORK"/ 2>/dev/null; [ -d wxis_src ] && cp -r wxis_src "$WORK"/)
sed -i 's/\r$//' "$WORK"/*.mak

echo "== CISIS | arch=$ARCH | variante=$VARIANT$SUF | UTF8=$UTF8 | gcc $(gcc -dumpversion) | alvos: $TARGETS"
FAIL=0; SUMMARY=""
for t in $TARGETS; do
  if [ ! -f "$WORK/$t.mak" ]; then SUMMARY="$SUMMARY\n  $t: FALTA $t.mak"; FAIL=1; continue; fi
  ( cd "$WORK" && rm -f -- *.o "$t" wxis_src/*.o 2>/dev/null
    make -j"$JOBS" -f "$t.mak" CC="$CC" CCFLAGS="$CCFLAGS" $V > "$LOGS/$t.log" 2>&1 )
  if [ -x "$WORK/$t" ]; then
    cp "$WORK/$t" "$DIST/$t"
    W=$(grep -c 'warning:' "$LOGS/$t.log")
    SUMMARY="$SUMMARY\n  $t: OK  ($W avisos)  -> dist/linux$ARCH/$VARIANT$SUF/$t"
  else
    E=$(grep -m1 -E 'error|undefined reference' "$LOGS/$t.log" | cut -c1-110)
    SUMMARY="$SUMMARY\n  $t: FALHOU  ${E}  (log: build/$ARCH-$VARIANT$SUF/logs/$t.log)"; FAIL=1
  fi
done
printf "$SUMMARY\n"

# confirmacao do banner (mx)
if [ -x "$DIST/mx" ]; then
  B=$("$DIST/mx" 2>&1 | head -1); echo "== banner: $B"
  if [ "$UTF8" = 1 ]; then case $B in *UTF-8*) :;; *) echo "AVISO: pedido UTF-8, mas o banner nao mostra UTF-8"; FAIL=1;; esac; fi
fi
exit $FAIL
