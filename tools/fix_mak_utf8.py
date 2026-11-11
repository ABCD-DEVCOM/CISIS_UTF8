#!/usr/bin/env python3
"""Acrescenta ciutf8.o (regra, dependencia e linha de ligacao) a um .mak da BIREME. Uso: fix_mak_utf8.py arq.mak ..."""
import re, sys
for f in sys.argv[1:]:
    raw = open(f, 'rb').read().decode('latin-1'); eol = '\r\n' if '\r\n' in raw else '\n'
    s = raw.replace('\r\n', '\n')
    if 'ciutf8' in s: print(f, ': ja tem ciutf8, nada a fazer'); continue
    name = f.rsplit('/', 1)[-1][:-4]
    # 1) dependencia do alvo:  "name: a.o b.o ..."  -> acrescenta ciutf8.o
    s, n1 = re.subn(r'(?m)^(%s:[^\n]*?\.o)[ \t]*$' % re.escape(name), r'\1 ciutf8.o', s, count=1)
    # 2) linha de ligacao: "$(CC) -o name ... $(CCLIBS)" -> insere ciutf8.o antes de $(CCLIBS)
    s, n2 = re.subn(r'(?m)^(\t\$\(CC\)[^\n]*? -o %s [^\n]*?)(\s*\$\(CCLIBS\)[^\n]*)$' % re.escape(name), r'\1 ciutf8.o\2', s, count=1)
    # 3) regra de compilacao
    if not s.endswith('\n'): s += '\n'
    s += '\nciutf8.o: ciutf8.c cisis.h\n\techo ciutf8..\n\t$(CC) $(CCOPTS) ciutf8.c\n'
    open(f, 'wb').write(s.replace('\n', eol).encode('latin-1'))
    print(f, ': alvo=%d ligacao=%d' % (n1, n2))
