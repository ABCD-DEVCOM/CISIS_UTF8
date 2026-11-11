#!/usr/bin/env python3
"""Computes the set of files really needed to build the targets (via .mak + gcc -MM). Usage: closure.py <root> target1 target2 ..."""
import re, subprocess, sys, os
root = sys.argv[1]; targets = sys.argv[2:]
need = set(); srcs = set(); hdrs = set()
def add_mak(t):
    p = os.path.join(root, t + '.mak')
    need.add(t + '.mak')
    txt = open(p, 'rb').read().decode('latin-1').replace('\r', '')
    for m in re.finditer(r'([A-Za-z0-9_./-]+\.(?:c|h|cpp))\b', txt):   # paths quoted in the commands (e.g. wxis_src/cimsrt.c)
        f = m.group(1)
        if os.path.exists(os.path.join(root, f)):
            (srcs if f.endswith(('.c','.cpp')) else hdrs).add(f)
    for m in re.finditer(r'([A-Za-z0-9_./\\-]+)\.o\b', txt):
        o = m.group(1).replace('\\', '/')
        for ext in ('.c', '.cpp'):
            if os.path.exists(os.path.join(root, o + ext)):
                srcs.add(o + ext); break
for t in targets: add_mak(t)
flagsets = [
  ['-DUTF8=1','-DCIFFI=1','-DSIXTY_FOUR=1','-DINCLOADX=1'],
  ['-DUTF8=0','-DCIFFI=0','-DSIXTY_FOUR=0'],
  ['-DUTF8=1','-DCIFFI=1','-DSUPERISIS=1','-DLIND=1'],
]
for s in sorted(srcs):
    for fl in flagsets:
        r = subprocess.run(['gcc','-MM','-MG','-I'+root,'-I'+os.path.join(root,'wxis_src')]+fl+['-DCICONF=1','-w',os.path.join(root,s)],
                           capture_output=True, text=True, cwd=root)
        for tok in re.split(r'\s+|\\\n', r.stdout.replace('\\\n',' ')):
            if tok and not tok.endswith(':') and not tok.endswith('.o:'):
                tok = os.path.relpath(os.path.join(root, tok), root) if not os.path.isabs(tok) else tok
                if os.path.exists(os.path.join(root, tok)) and not tok.endswith('.o'): hdrs.add(tok)
allf = sorted(need | srcs | hdrs)
print("\n".join(allf))
sys.stderr.write("sources=%d  headers=%d  makefiles=%d  total=%d\n" % (len(srcs), len(hdrs - srcs), len(need), len(allf)))
