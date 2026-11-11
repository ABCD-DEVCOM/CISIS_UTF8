@echo off
REM build_windows_bcc55.bat - compila mx.exe e wxis.exe (UTF-8) com Borland C++ 5.5 a partir da RAIZ do repositorio.
REM Baseado nos .bat oficiais de CISIS_UNI_Win\projects (mesmas listas de arquivos e flags).
REM *** NAO TESTADO: precisa rodar num Windows com o BCC55. Se falhar, guarde a saida e compare com os .bat oficiais. ***
REM Uso:  build_windows_bcc55.bat [ffi|1660]      (padrao: ffi = o mesmo tipo do wxis do ABCD: F/M/1048576)
setlocal
cd /d "%~dp0"
if "%BCC%"=="" set BCC=C:\Borland\BCC55
if not exist "%BCC%\Bin\bcc32.exe" (
  echo bcc32.exe nao encontrado em %BCC%\Bin. Defina a variavel BCC ou rode find_compilers.ps1
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

REM INCLOADX=1 faz o CISIS ler uctab=/actab= do .par (necessario para russo, grego, hebraico...)
set COMMON=-I"%BCC%\Include" -DUTF8=1 -DINCLOADX=1 -DCIFFI=%FFI% -DLIND=0 -DLIND4=0 -DCIWTF=1 -DISISXL=1 -DISISXL512=0 -DINCPROCX=1 -DINCPRECX=1

echo ===== mx =====
bcc32 %COMMON% -DGCC=0 -DPC=1 -DDOS32BITS=1 -DMSC=0 -DUNIX=0 -DWWWISIS=0 -DEXCFMCGI=0 -DEXCFMXML=0 -D_FILE_OFFSET_BITS=0 -D_LARGEFILE64_SOURCE=0 -DPCREADLINUX=0 -c mx.c mxaot.c ifloadao.c ciifl.c cisisx.c mxrun.c mxrel.c mxtxt.c mxbol.c cib71.c cib72.c cifm1.c cifm2.c cifm3.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciupi.c ciiso.c ciutl.c cifst.c ciifu.c cicgi.c mys.c ciutf8.c
if errorlevel 1 goto erro
bcc32 -L"%BCC%\Lib" -e%OUT%\mx.exe mx.obj mxaot.obj ifloadao.obj ciifl.obj cisisx.obj mxrun.obj mxrel.obj mxtxt.obj mxbol.obj cib71.obj cib72.obj cifm1.obj cifm2.obj cifm3.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciupi.obj ciiso.obj ciutl.obj cifst.obj ciifu.obj cicgi.obj mys.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj

echo ===== wxis =====
bcc32 %COMMON% -DWWWISIS=1 -c cidbx.c cirec.c cigiz.c citrm.c ciupd.c cifm1.c cifm2.c cifm3.c ciutl.c cib71.c cib72.c cifst.c ciifu.c ciupi.c ciifl.c cicgi.c ciiso.c mxaot.c mxrun.c mxrel.c mxtxt.c mxbol.c ifloadao.c mys.c ciutf8.c
if errorlevel 1 goto erro
cd wxis_src
bcc32 %COMMON% -DWWWISIS=1 -c xis.c xis_exec.c xis_comp.c easyfc.c easyci.c arglist.c cgilist.c citpv.c freqlist.c hide.c hlfill.c cimsrt.c cixml.c
if errorlevel 1 goto erro
cd ..
bcc32 -L"%BCC%\Lib" -e%OUT%\wxis.exe cidbx.obj cirec.obj cigiz.obj citrm.obj ciupd.obj cifm1.obj cifm2.obj cifm3.obj ciutl.obj cib71.obj cib72.obj cifst.obj ciifu.obj ciupi.obj ciifl.obj cicgi.obj ciiso.obj mxaot.obj mxrun.obj mxrel.obj mxtxt.obj mxbol.obj ifloadao.obj mys.obj wxis_src\xis.obj wxis_src\xis_exec.obj wxis_src\xis_comp.obj wxis_src\easyfc.obj wxis_src\easyci.obj wxis_src\arglist.obj wxis_src\cgilist.obj wxis_src\citpv.obj wxis_src\freqlist.obj wxis_src\hide.obj wxis_src\hlfill.obj wxis_src\cimsrt.obj wxis_src\cixml.obj ciutf8.obj
if errorlevel 1 goto erro
del *.obj
del wxis_src\*.obj
del *.tds 2>nul
del %OUT%\*.tds 2>nul
echo.
echo PRONTO: %OUT%\mx.exe e %OUT%\wxis.exe
%OUT%\mx.exe
exit /b 0

:erro
echo.
echo *** FALHOU (veja a mensagem acima) ***
exit /b 1
