@echo off
REM build_windows_tools_bcc55.bat - GERADO por tools/gen_bcc_tools.py (nao editar a mao).
REM Compila os utilitarios do ABCD com Borland C++ 5.5: crunchif crunchmf retag ifkeys i2id id2i
REM Mesmas flags de plataforma do mx.exe de build_windows_bcc55.bat; as flags de formato (CIWTF/INCPROCX/...)
REM sao as dos .mak da BIREME para estes utilitarios.
REM *** NAO TESTADO: precisa rodar num Windows com o BCC55. ***
REM Uso: build_windows_tools_bcc55.bat [ffi|1660]
setlocal
cd /d "%~dp0"
if "%BCC%"=="" set BCC=C:\Borland\BCC55
if not exist "%BCC%\Bin\bcc32.exe" (
  echo bcc32.exe nao encontrado em %BCC%\Bin. Defina a variavel BCC.
  exit /b 1
)
set PATH=%BCC%\Bin;%PATH%
set VAR=%1
if "%VAR%"=="" set VAR=ffi
set FFI=1
if "%VAR%"=="1660" set FFI=0
set OUT=dist\windows32\%VAR%
if not exist dist mkdir dist
if not exist dist\windows32 mkdir dist\windows32
if not exist %OUT% mkdir %OUT%
set PLAT=-DGCC=0 -DPC=1 -DDOS32BITS=1 -DMSC=0 -DUNIX=0 -DUTF8=1 -DINCLOADX=1 -DCIFFI=%FFI% -DLIND=0 -DLIND4=0 -DISISXL=1 -DISISXL512=0 -DWWWISIS=0 -D_FILE_OFFSET_BITS=0 -D_LARGEFILE64_SOURCE=0 -DPCREADLINUX=0
set FMT=-DCIWTF=0 -DINCPROCX=0 -DINCPRECX=0 -DEXCFMCGI=1 -DEXCFMXML=1
set OPT=-I"%BCC%\Include" %PLAT% %FMT%

echo ===== crunchif =====
bcc32 %OPT% -c crunchif.c cidbx.c cigiz.c cirec.c ciupd.c ciutl.c citrm.c ciutf8.c
if errorlevel 1 goto erro
bcc32 -L"%BCC%\Lib" -e%OUT%\crunchif.exe crunchif.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj ciutl.obj citrm.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj

echo ===== crunchmf =====
bcc32 %OPT% -c crunchmf.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciutl.c ciutf8.c
if errorlevel 1 goto erro
bcc32 -L"%BCC%\Lib" -e%OUT%\crunchmf.exe crunchmf.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciutl.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj

echo ===== retag =====
bcc32 %OPT% -c retag.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciutl.c ciutf8.c
if errorlevel 1 goto erro
bcc32 -L"%BCC%\Lib" -e%OUT%\retag.exe retag.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciutl.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj

echo ===== ifkeys =====
bcc32 %OPT% -c ifkeys.c cidbx.c citrm.c ciutf8.c
if errorlevel 1 goto erro
bcc32 -L"%BCC%\Lib" -e%OUT%\ifkeys.exe ifkeys.obj cidbx.obj citrm.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj

echo ===== i2id =====
bcc32 %OPT% -c i2id.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciutl.c ciutf8.c
if errorlevel 1 goto erro
bcc32 -L"%BCC%\Lib" -e%OUT%\i2id.exe i2id.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciutl.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj

echo ===== id2i =====
bcc32 %OPT% -c id2i.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciutl.c ciutf8.c
if errorlevel 1 goto erro
bcc32 -L"%BCC%\Lib" -e%OUT%\id2i.exe id2i.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciutl.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj

del *.tds 2>nul
del %OUT%\*.tds 2>nul
echo.
echo PRONTO: %OUT%
exit /b 0

:erro
echo.
echo *** FALHOU (veja a mensagem acima) ***
exit /b 1
