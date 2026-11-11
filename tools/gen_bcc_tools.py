#!/usr/bin/env python3
"""Gera build_windows_tools_bcc55.bat a partir dos .mak (listas de objetos de cada utilitario).
Uso (na raiz do repositorio):  python3 tools/gen_bcc_tools.py crunchif crunchmf retag ifkeys i2id id2i > build_windows_tools_bcc55.bat"""
import re, sys
tools = sys.argv[1:] or ['crunchif', 'crunchmf', 'retag', 'ifkeys', 'i2id', 'id2i']
out = []
out.append('''@echo off
REM build_windows_tools_bcc55.bat - GERADO por tools/gen_bcc_tools.py (nao editar a mao).
REM Compila os utilitarios do ABCD com Borland C++ 5.5: %s
REM Mesmas flags de plataforma do mx.exe de build_windows_bcc55.bat; as flags de formato (CIWTF/INCPROCX/...)
REM sao as dos .mak da BIREME para estes utilitarios.
REM *** NAO TESTADO: precisa rodar num Windows com o BCC55. ***
REM Uso: build_windows_tools_bcc55.bat [ffi|1660]
setlocal
cd /d "%%~dp0"
if "%%BCC%%"=="" set BCC=C:\\Borland\\BCC55
if not exist "%%BCC%%\\Bin\\bcc32.exe" (
  echo bcc32.exe nao encontrado em %%BCC%%\\Bin. Defina a variavel BCC.
  exit /b 1
)
set PATH=%%BCC%%\\Bin;%%PATH%%
set VAR=%%1
if "%%VAR%%"=="" set VAR=ffi
set FFI=1
if "%%VAR%%"=="1660" set FFI=0
set OUT=dist\\windows32\\%%VAR%%
if not exist dist mkdir dist
if not exist dist\\windows32 mkdir dist\\windows32
if not exist %%OUT%% mkdir %%OUT%%
set PLAT=-DGCC=0 -DPC=1 -DDOS32BITS=1 -DMSC=0 -DUNIX=0 -DUTF8=1 -DINCLOADX=1 -DCIFFI=%%FFI%% -DLIND=0 -DLIND4=0 -DISISXL=1 -DISISXL512=0 -DWWWISIS=0 -D_FILE_OFFSET_BITS=0 -D_LARGEFILE64_SOURCE=0 -DPCREADLINUX=0
set FMT=-DCIWTF=0 -DINCPROCX=0 -DINCPRECX=0 -DEXCFMCGI=1 -DEXCFMXML=1
set OPT=-I"%%BCC%%\\Include" %%PLAT%% %%FMT%%
''' % ' '.join(tools))
for t in tools:
    mak = open(t + '.mak', 'rb').read().decode('latin-1').replace('\r\n', '\n')
    m = re.search(r'(?m)^\t\$\(CC\)\s+-o\s+%s\s+(.*?)\s*\$\(CCLIBS\)' % re.escape(t), mak)
    if not m: sys.exit('ERRO: nao achei a linha de ligacao de %s.mak' % t)
    objs = m.group(1).split()
    srcs = [o[:-2] + '.c' for o in objs if o.endswith('.o')]
    out.append('echo ===== %s =====' % t)
    out.append('bcc32 %%OPT%% -c %s' % ' '.join(srcs))
    out.append('if errorlevel 1 goto erro')
    out.append('bcc32 -L"%%BCC%%\\Lib" -e%%OUT%%\\%s.exe %s' % (t, ' '.join(o[:-2] + '.obj' for o in objs if o.endswith('.o'))))
    out.append('if errorlevel 1 goto erro')
    out.append('del *.obj')
    out.append('')
out.append('del *.tds 2>nul')
out.append('del %OUT%\\*.tds 2>nul')
out.append('echo.')
out.append('echo PRONTO: %OUT%')
out.append('exit /b 0')
out.append('')
out.append(':erro')
out.append('echo.')
out.append('echo *** FALHOU (veja a mensagem acima) ***')
out.append('exit /b 1')
sys.stdout.buffer.write(('\n'.join(out) + '\n').replace('\r\n','\n').replace('\n','\r\n').encode('latin-1'))
