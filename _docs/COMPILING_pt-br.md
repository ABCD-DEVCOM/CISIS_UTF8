# Compilando o CISIS (UTF-8): Linux e Windows, 32 e 64 bits

> **Nota:** este é o original em português. A versão mantida é [`COMPILING.md`](COMPILING.md) (inglês), já atualizada: o padrão do `build_linux.sh` agora é `isis1660` (não `ffi1660`), são 14 variantes (`-v list`), há `build_all.sh` e `build_windows_all_bcc55.bat`. Os limites exatos de cada variante estão em [`LIMITS.md`](LIMITS.md).

## O que foi verificado e o que não foi

| Alvo | Estado |
|---|---|
| Linux 32 bits, UTF-8, `ffi1660` | ✔ 37 programas compilam; 21/21 testes (`smoke_test.sh`); `bigisis` testado com os 8 principais |
| Linux 64 bits, UTF-8, executável PIE padrão (com os patches 2 e 3) | ✔ 37 programas; 21/21 testes; 758 formatos reais do ABCD dão **saída idêntica à do 32 bits**; AddressSanitizer sem achados (rodada com os 8 principais) |
| Linux 32 e 64 bits, **ANSI** (`-u 0`) | ✔ 39 programas; 16/16 testes (`smoke_test_ansi.sh`, dados ISO-8859-1) |
| Windows 32 bits, Borland C++ 5.5: `mx.exe`, `wxis.exe` | ✔ compilado no seu Windows (0 erros, 342 avisos) |
| Windows 32 bits, BCC55: utilitários | ✔ compilado no seu Windows depois do patch do `ifkeys.c` (o código original dava `E2349` nas linhas 66 e 76); **falta testar o funcionamento no ABCD** |
| Windows 64 bits (MinGW-w64) | **só a compilação foi verificada** (ver "Windows 64 bits"); não foi executado |

## Os programas do ABCD

A lista de `cgi-bin/ansi` do ABCD (37 programas: `i2id id2i ifkeys ifload ifp1 ifupd lydump lyfreq mdl2i mdl2ir mdlif mdlmf mdlup mkiy0 mkxrf msrt mx mxcp mxf0 mxget mxgw mxmys mxtb mys myz myzcru mz retag rule serw serw2 serx sizeof sizeof2 splitem splitm wxis`) mais `crunchif` e `crunchmf` (que o PHP do ABCD usa e não estão naquela lista) formam o **conjunto de 39**. Todos têm `.mak` (os 18 que faltavam vieram do original da BIREME, ver patch 3). Em **UTF-8** compilam 37; `mxgw` e `mz` só compilam em ANSI (ver "Programas ainda não portados"). `mx wxis ifkeys crunchif crunchmf retag i2id id2i` têm teste funcional; os demais foram compilados e **executados sem argumentos sem travar**, mas não têm teste de resultado. `pdftohtml` **não é do CISIS** (é do Poppler/Xpdf): Linux `apt install poppler-utils`; Windows, um build do Poppler. Os `.mak` de `crunchif`, `crunchmf`, `retag`, `i2id`, `id2i`, `mxcp`, `msrt`, `mxf0`, `ifload`, `ifmerge` não existiam no repositório UTF-8; o patch 1 (já no repositório) os restaurou da BIREME já com `ciutf8.o`. `tools/fix_mak_utf8.py` faz o mesmo com outros `.mak`.

## Linux

```bash
sudo apt install build-essential            # gcc e make
sudo apt install gcc-multilib libc6-i386    # só para 32 bits

./build_linux.sh                  # 32 bits, ffi1660, mx + wxis   -> dist/linux32/ffi1660/
./build_linux.sh -t "mx wxis ifkeys crunchif crunchmf retag i2id id2i"    # o conjunto do ABCD
./build_linux.sh -a 64            # 64 bits (PIE automático se o cisis.h tem CIPTR)
./build_linux.sh -v bigisis       # registros grandes / arquivos > 2 GB
./build_linux.sh -s               # char com sinal (como o BCC55)
./build_linux.sh -t all           # todos os .mak (em UTF-8 pula mxgw e mz, com aviso)
./build_linux.sh -a 64 -u 0 -t all  # build ANSI (UTF8=0) -> dist/linux64/ffi1660-ansi/
./smoke_test.sh dist/linux64/ffi1660              # UTF-8
./smoke_test_ansi.sh dist/linux64/ffi1660-ansi    # ANSI (dados ISO-8859-1)
```

Objetos em `build/`, binários em `dist/`. O banner do `mx` mostra o build (`.../F/M/1048576/16/60/I/64bits/UTF-8`).

### 32 ou 64 bits

Os dois funcionam depois dos patches. Antes, o 64 bits tinha dois problemas de fundo:

1. **Ponteiros guardados em `int`.** No modo `SIXTY_FOUR`, `LONGX` é `int`, e o compilador de formatos (PFT) guardava endereços nos campos `info.add`, `m_add` e `next` de `FMT_CODE`, além de `address`/`field_address`, `gen()`, `store_*_const()` e a tabela `rotulos`. Num executável PIE (padrão do gcc) isso dava *segfault* em qualquer formato. O patch 2 introduz `CIPTR` (inteiro do tamanho de um ponteiro: `long` no Linux 64, `long long` no Windows 64, `long` nos 32 bits) nesses pontos (154 avisos de conversão viraram 0). O `build_linux.sh` usa PIE se o `cisis.h` tiver `CIPTR`, senão `-no-pie`.
2. **Cópias com regiões sobrepostas** (ver abaixo), que a `glibc` de 64 bits trata diferente da de 32 e corrompiam texto: `mdl,v245` dava `Titu de teste /, Autor Exemplolo.` em vez de `Titulo de teste /, Autor Exemplo.`.

32 bits continua sendo a escolha mais conservadora (mesmo modelo de dados do Windows 32); precisa de `libc6-i386` num Ubuntu 64 bits.

## Defeitos corrigidos

**Patch 1 (`cisis_fixes_utf8.patch`) — já está no repositório** (commit `1243af2`, conferido: `citrm.c` com `highv = 0xFF`, `ifkeys.c` com o bloco UTF8, `.mak` com `ciutf8.o`). Não aplique de novo: o `git apply` reclama de "already exists".
- `citrm.c`: o fim do dicionário (`highv`) era `0x7F` fora do Windows; chaves UTF-8 (russo, hebraico, acentos) comparavam como "depois do fim". `ifkeys` listava 7 de 11 termos, buscas com truncamento (`ПРИВ$`) davam 0, a lista de termos do OPAC (`processar_ifkeys.php`) saía incompleta no Linux. Correção: `#if PC || UTF8`.
- `ifkeys.c`: `from=`/`to=` davam segfault (gravava ponteiro em string literal).
- `.mak` sem `ciutf8.o` (erro de ligação).

**Patch 2 (`cisis_fixes_64bit.patch`) — este é o que falta aplicar.** Conferido com `git apply --check` sobre o `1243af2`; no PowerShell: `git apply --whitespace=nowarn cisis_fixes_64bit.patch`.
- `cisis.h`, `cifm1.c`, `cifm2.c`, `cifm3.c`, `cifmt.h`, `wtrun.c`: `CIPTR` (ver acima).
- `cifm2.c`, `sub_field_change`: `strcat(q,ps)` com origem dentro do próprio destino (comportamento indefinido) → `memmove`. Corrompia `mdl`/`mdu` no 64 bits.
- `cifm3.c`: `strcpy(tmp_ptr, sub_string(tmp_ptr,...))` com sobreposição → `memmove` (120 execuções nos formatos do ABCD).
- `cifm1.c`, `getsymbol`: `ssym[128]` indexado com bytes `> 127` dentro de **comentários de formato com acento** (`/* ação */`) lia fora do vetor → macro `SSYM(c)` com limite.
- `cifm2.c`, `out_put_str`: lia `s[inicio+t]` antes de testar `t>=0` (1 byte antes do buffer).
- `cib71.c`, `gettoken`: o analisador de expressões booleanas lia 1 byte antes do buffer (`*(p-1)`); novo `PREVWHITE(p)`.

Estes seis últimos valem para **todas** as plataformas (no Windows/BCC55 liam lixo sem avisar).

### Como foi verificado
- 758 formatos `.pft` distintos do ABCD (de 1944 arquivos) rodados contra uma base UTF-8 sintética: 32 bits e 64 bits PIE idênticos (758/758, mascarando datas); sob AddressSanitizer, 0 achados depois das correções (eram 3 tipos antes).
- 234 buscas booleanas × 13 variantes de FST, `crunchif/crunchmf/i2id/id2i/ifkeys` sob AddressSanitizer: 0 achados.
- `-s` (char com sinal, como o BCC55): 21/21 também.

## Comportamento que não é defeito
- `crunchmf`/`crunchif` **sem `target=` convertem para o formato da OUTRA plataforma** (é o que `db_convert_crunchmf.php` do ABCD usa). Para compactar na mesma plataforma: `target=linux` (Linux) ou `target=pc` (Windows).
- **`-DINCLOADX=1` é necessário para UTF-8 multilíngue**: sem ele o CISIS ignora `uctab=`/`actab=` do `.par` e russo/hebraico não são indexados nem achados. O `build_linux.sh` e os `.bat` gerados já passam a flag; os `.bat` oficiais não.
- O CISIS só lê as chaves `uctab=` e `actab=` (não `isisac.tab=`/`isisuc.tab=`). `isisactab_utf8.tab` do ABCD não tem hebraico; `tests/isisactab_utf8_he.tab` acrescenta U+05D0..U+05EA.
- O FST precisa de `mpu` (`1 4 mpu,v1`). `ÁGU$` (acento no prefixo truncado) não acha `AGUA` indexado com `mpu`: observado, não investigado.

## Windows 32 bits

```powershell
powershell -ExecutionPolicy Bypass -File .\find_compilers.ps1
build_windows_bcc55.bat            # mx.exe e wxis.exe        -> dist\windows32\ffi\
build_windows_tools_bcc55.bat      # utilitários do ABCD      -> dist\windows32\ffi\
```
O BCC55 grava os `.tds` ao lado do `.exe`; os `.bat` agora apagam `%OUT%\*.tds`. Os `.exe` oficiais usam `char` com sinal (sem `-K`).

## Windows 64 bits

Para o ABCD **não é necessário**: os `.exe` de 32 bits rodam no Windows 64. Se quiser um nativo de 64 bits:
- **O que já está pronto:** `CIPTR` vira `long long` sob `_WIN64` (o Windows 64 é LLP64: `long` tem 32 bits). Com MinGW-w64 de 64 bits, `cifm1.c`, `cifm2.c`, `cifm3.c`, `cib72.c`, `cidbx.c` e `cirec.c` compilam e restou **1** aviso de conversão ponteiro/inteiro (uma linha de depuração em `cib72.c:2852`).
- **O que falta:** compilar e **executar** o conjunto completo. As rotas seriam MSYS2 (`mingw-w64-x86_64-gcc`) ou o Visual Studio 2022 (`cl.exe`, flag `MSC`). Meu teste com MinGW 32 bits sob wine falhou em tempo de execução (`format syntax | Invalid operand class` em `replace(s(cat(...)))`), e isso precisa ser reproduzido e resolvido num Windows real antes de contar com MinGW. Também faltam, no código, os remendos de portabilidade do MinGW (`alloc.h`, `sys\stat.h`, sockets, `_rtl_*`, `lock`/`unlock`, `O_DENYNONE`, `MAXPATH`).
- Sugestão: primeiro validar no MSYS2 o `mx` com o `smoke_test.sh` (precisa de bash, vem com o MSYS2).

## Avisos do compilador
**BCC55** (175 distintos): 154 são estilo; o resto é inofensivo ou revisável: `cifm2.c:604,633` (falta cast em `strlen_UTF8`/`skipchar_UTF8`), `easyfc.c:171-197` (falta `#include <io.h>`), `cisisx.c:2539` (`LSEEK64(fd,-sizeof(...))` nega `size_t`; revisar nas variantes grandes), `cifst.c:1534` (comparação sempre falsa).
**gcc 32 bits `-Wall`** (~3.500 ocorrências): quase tudo ruído (`-Wswitch` 2145, `-Wmissing-braces` 382, `-Wpointer-sign` 362, `-Wattributes` 290). Locais que podem esconder defeito: ~70 (`-Wformat` 30, `-Wformat-overflow` 10, `-Wint-conversion` 7, `-Wimplicit-function-declaration` 7, `-Wformat-security` 4, `-Wmaybe-uninitialized` 3, ...). Plano: triar esses, corrigir e ligar `-Werror=` só para essas categorias.

## Programas ainda não portados para UTF-8
`mxgw` e `mz` leem a tabela `isiswctab` byte a byte para separar palavras; em UTF-8 isso exige reescrever o laço com `alphabetic_utf8()`/`skipchar_utf8()` (como já está em `cifm3.c` e `mxrel.c`). Compilam em ANSI (`-u 0`) e ficam assim até o porte. Os outros (`ifp1`, `ifupd`, `mdlmf`, `mxtb`) foram portados no patch 3 (`uppercase_utf8`, `loaductb_utf8`/`loadactb_utf8`, `isisuctab_utf8` no `b7_run`) e **só têm teste de compilação e de partida**, sem teste funcional de resultado.
`splitm`: o `.mak` do repositório tinha `ciutf8.o` a mais e não ligava; o patch 3 volta ao da BIREME (o programa não usa a biblioteca).

## Duas árvores de fonte
`CISIS_UNI_Win/sources` **não é o original da BIREME** (o original, github.com/bireme/cisis, não tem `UTF8` em `cisis.h` nem `ciutf8.c`). É uma árvore já modificada (UTF-8, v6.0a) que gerou os `.exe` oficiais e diverge da raiz (por exemplo `cifm3.c:580` com `p++;q++;`). Mantenha-a numa branch ou em `legacy/`.

## Bug conhecido do WXIS: parm desconhecido
`xis_exec.c`, `exeParm()`: `cplIdentifier()` devolve `ATVALUE_LIST_QTT` para nomes de parm inexistentes e `atValueParm[...]` é lido com esse índice (uma posição além do array). Nos `.exe` oficiais derruba o WXIS (o `crear_registro.xis` tinha `MAX_TMP_STRING`). Correção, antes de `parmIndex = atValueParm[...]`:
```c
if (cmd->attributeList[ATTRIBUTE_NAME].atValue >= ATVALUE_LIST_QTT) return; /* parm desconhecido: ignora */
```
Ainda não confirmada recompilando um `.exe` Windows.

## Compilar em ANSI (`UTF8=0`)
Funciona: `./build_linux.sh -u 0 ...` passa `-DUTF8=0` e grava em `dist/.../<variante>-ansi`. Verificado: os 39 programas compilam em 32 e 64 bits e `smoke_test_ansi.sh` dá 16/16 com dados ISO-8859-1. A mesma árvore gera as duas versões, mas **não misture**: base ANSI com binário UTF-8 (e o inverso) corrompe acentos.

Atenção ao `.par`: nenhum `.mak` da BIREME (nem os deste repositório) define `INCLOADX`, então um binário ANSI compilado como eles **ignora `uctab=`/`actab=` do `.par`**. Sem tabela só o ASCII é letra, e `Água e Ação` é indexado como `A`, `GUA`, `O` (verificado no `ifkeys`). O `smoke_test_ansi.sh` passa as tabelas como opções do `mx` por isso.
`-x 1` liga `INCLOADX` no ANSI e o `.par` passa a valer (verificado: `água` 2 resultados, `AGU$` 2, `ça` 1, só com o `.par`), mas **é experimental**: ligam 29 de 39; `ifkeys lydump lyfreq mdl2i mdl2ir mkiy0 myz myzcru sizeof splitem` não ligam (os `.mak` delas linkam poucos objetos; só acrescentar `ciutl.o` não basta, aparece `recxrefb`). Não use `-x 1` para o conjunto do ABCD antes de decidir isso: muda como as bases ANSI existentes são indexadas.

## Até quando os binários de 32 bits funcionam?
Não achei data anunciada de fim, em nenhum dos dois sistemas. O que foi verificado:
- **Windows (x64):** o Windows 11 só existe em 64 bits e continua executando programas de 32 bits (WOW64); um artigo de 20/10/2026 mostra o WOW64 funcionando no Windows 11 26H2 e não relata plano de remoção ([Windows Latest](https://www.windowslatest.com/2026/10/20/why-windows-11-keeps-64-bit-files-in-system32-and-32-bit-files-in-syswow64-according-to-microsoft/)); outro, de 09/05/2026, diz o mesmo e que 25H2 deixou de instalar em hardware x86 antigo ([Born City](https://borncity.com/news/windows-11-microsoft-verabschiedet-sich-von-32-bit-aber-nicht-von-alter-software/)). A remoção que existe é de aplicativos **ARM32** no Windows em ARM, o que não atinge x64 ([WinFuture](https://winfuture.de/news,137385.html)). Não consegui abrir a documentação da Microsoft (bloqueada neste ambiente), então não há citação oficial.
- **Linux (x86-64):** o kernel executa 32 bits por `IA32_EMULATION`; desde o 6.7 dá para desligar na inicialização (`ia32_emulation=`) e distribuições estudavam desligar por padrão ([Phoronix](https://phoronix.com/news/Linux-6.8-x86-32-bit-Warning)). A discussão de 2026 no kernel é sobre o **x32**, outro ABI, não sobre o i386 que o `-m32` usa ([LWN, 01/06/2026](https://lwn.net/Articles/1074897/)). No Debian 13, o i386 deixou de ser arquitetura completa e ficou só para rodar código legado via multiarch ([The Register](https://www.theregister.com/2025/08/12/debian_13_trixie_released/)). Aqui, em Ubuntu 24.04 com kernel 6.18, os binários 32 bits compilaram e rodaram nesta rodada.
- **Risco prático:** não é o Windows, e sim servidores Linux enxutos ou contêineres sem `libc6-i386`. Por isso o 64 bits PIE (com os patches 2 e 3) é a escolha para Linux; no Windows os `.exe` de 32 bits (BCC55) seguem sendo os testados em campo.

## Limpeza do repositório
O HEAD tem 554 arquivos rastreados (21 MB). `tools/limpar_repo.sh` separa:
- **mantém 182**: o fecho de dependências dos 39 programas + `wxis` (calculado dos `.mak` e do `gcc -MM`; `tools/closure.py` refaz a conta) e o kit;
- **apaga 313**: binários (`1660utf8/` com 35 executáveis Linux, `ifkeys`, `main.o`, `wxis.exe`), saídas de IDE do Borland (`mx.csm` 3 MB, `.ils .ilf .ilc .ild .mbt .mrt .DSW`), `err.out`, `cisis.h.save*`, cópias soltas (`ciutf8.c2`, `easyfc(1).c`, `easyfc.c.57e*`) e **245 arquivos idênticos ao original da BIREME** (outros programas, versão C++, exemplos do wxis), recuperáveis de https://github.com/bireme/cisis ou da tag de segurança;
- **move 59 para `legacy/`**: o que difere da BIREME ou só existe aqui (scripts `makemake*`/`mk*`/`generateAll*`, `.mak` dos programas fora da lista do ABCD, `cifm3_standard.c`, `stdio.h` do Borland, `changes.txt` da árvore 5.7e).
Prova: uma árvore montada só com o que fica compila e passa nos mesmos testes (37 e 39 binários; 21/21 e 16/16). Rode primeiro sem argumentos (simulação) e depois com `--aplicar`; ele cria a tag `pre-limpeza-AAAAMMDD` e faz `git rm`/`git mv`, então o histórico fica.
Pontos para você decidir: `legacy/` pode ser apagada depois; os exemplos do wxis (123 arquivos) saem por serem idênticos à BIREME, e se quiser mantê-los como documentação tire-os da lista `APAGAR`.

## A árvore UTF-8 é a 5.7e; a BIREME avançou
`changes.txt` da BIREME registra a **5.7f (13/01/2015)**: o comprimento do registro no gizmo passou de 6 para 8 dígitos. Conferido no código: `cigiz.c` desta árvore ainda grava `H%u 000000` (linhas 561-562 e 631), a BIREME grava `00000000`. Dos 156 fontes/cabeçalhos do núcleo, **26 diferem** do HEAD da BIREME (130 iguais, 4 só aqui: `ciutf8.c`, `ciutf8.h`, `easyfc.c`, `stdio.h`). As diferenças misturam o trabalho de UTF-8 (`cisis.h`, `cirun.h`, `cifm3.c`, `cifst.c`, `cib72.c`, `mxaot.c`, `ciupdsplt.c`...) com correções posteriores que faltam aqui. Ainda **não separei** uma coisa da outra: precisaria da base 5.7e original (histórico da BIREME) para uma mescla de três vias.
