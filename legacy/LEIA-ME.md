# legacy/

Arquivos que **nao** sao necessarios para compilar os programas do ABCD, mas que diferem do original da BIREME
ou existiam so neste repositorio. Ficam aqui para consulta; nada daqui entra na compilacao.

- `scripts/`  scripts antigos de geracao (`makemake*.xsh`, `mk*.xsh`, `generateAll*`, `.bat`, `.cfg` do Borland). Substituidos por `build_linux.sh` e `build_windows_*.bat`.
- `mak/`      `.mak` de programas da BIREME que o ABCD nao usa (aotmsa2, b7, chkterm, decs9a/b, decsex, fxl0, ifmerge, wtrig1/2), ja com `ciutf8.o`.
- `fontes/`   fontes alterados ou so deste repositorio (`cifm3_standard.c`, `appeasy.c`, `changes.txt` da arvore 5.7e, `stdio.h` do Borland, exemplos).

O restante do codigo da BIREME (outros programas, versao C++, exemplos do wxis) foi removido por ser identico ao original:
https://github.com/bireme/cisis   (tambem na tag `pre-limpeza-*` deste repositorio).
