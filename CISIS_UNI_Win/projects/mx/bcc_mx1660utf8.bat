SET PATH=%PATH%;c:\Borland\BCC55\bin

cd ..\..\sources
REM Dropped -D in next line : -DINCPROCX=1 -DINCPRECX=1 -DEXCFMCGI=0 -DEXCFMXML=0 -D_FILE_OFFSET_BITS=0 -D_LARGEFILE64_SOURCE=0 -DPCREADLINUX=0

bcc32 -I"C:\Borland\BCC55\Include" -DGCC=0 -DUTF8=1 -DPC=1 -DDOS32BITS=1 -DMSC=0 -DUNIX=0 -DWWWISIS=0 -DCIFFI=0 -DLIND=0  -DLIND4=0 -DCIWTF=1 -DISISXL=1 -DISISXL512=0 -DINCPROCX=1 -DINCPRECX=1 -DEXCFMCGI=0 -DEXCFMXML=0 -D_FILE_OFFSET_BITS=0 -D_LARGEFILE64_SOURCE=0 -DPCREADLINUX=0 -c mx.c mxaot.c ifloadao.c ciifl.c cisisx.c mxrun.c mxrel.c mxtxt.c mxbol.c cib71.c cib72.c cifm1.c cifm2.c cifm3.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciupi.c ciiso.c ciutl.c cifst.c ciifu.c cicgi.c mys.c ciutf8.c

REM bcc32 -L"C:\Win-Builds\Lib" 

bcc32 -L"C:\Borland\BCC55\Lib" -e..\projects\mx\mx1660utf8.exe mx.obj mxaot.obj ifloadao.obj ciifl.obj cisisx.obj mxrun.obj mxrel.obj mxtxt.obj mxbol.obj cib71.obj cib72.obj cifm1.obj cifm2.obj cifm3.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciupi.obj ciiso.obj ciutl.obj cifst.obj ciifu.obj cicgi.obj mys.obj ciutf8.obj

del *.obj
cd ..\projects\mx
del *.tds
