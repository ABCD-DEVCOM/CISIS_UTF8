REM SET PATH=%PATH%;c:\Borland\BCC55\bin

cd ..\..\sources

bcc32 -I"C:\Borland\BCC55\Include" -DUTF8=1 -DWWWISIS=0 -DCIFFI=1 -DLIND=0 -DCIWTF=1 -DISISXL=1 -c mx.c mxaot.c ifloadao.c ciifl.c cisisx.c mxrun.c mxrel.c mxtxt.c mxbol.c cib71.c cib72.c cifm1.c cifm2.c cifm3.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciupi.c ciiso.c ciutl.c cifst.c ciifu.c cicgi.c mys.c ciutf8.c

bcc32 -L"C:\Borland\BCC55\Lib" -e..\projects\mx\mxffi.exe mx.obj mxaot.obj ifloadao.obj ciifl.obj cisisx.obj mxrun.obj mxrel.obj mxtxt.obj mxbol.obj cib71.obj cib72.obj cifm1.obj cifm2.obj cifm3.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciupi.obj ciiso.obj ciutl.obj cifst.obj ciifu.obj cicgi.obj mys.obj ciutf8.obj

del *.obj
cd ..\projects\mx
del *.tds
