SET PATH=%PATH%;c:\Win-Builds\bin

cd ..\..\sources
cc -I"C:\Win-Bilds\Include" -DUTF8=1 -DGCC=1 -DWWWISIS=0 -DCIFFI=0 -DLIND=0 -DCIWTF=1 -DISISXL=0 -c mx.c mxaot.c ifloadao.c ciifl.c cisisx.c mxrun.c mxrel.c mxtxt.c mxbol.c cib71.c cib72.c cifm1.c cifm2.c cifm3.c cidbx.c cigiz.c cirec.c ciupd.c citrm.c ciupi.c ciiso.c ciutl.c cifst.c ciifu.c cicgi.c mys.c ciutf8.c >compilation1660.log

cc -L"C:\Win-Builds\Lib" -e..\projects64\mx\mx.exe mx.obj mxaot.obj ifloadao.obj ciifl.obj cisisx.obj mxrun.obj mxrel.obj mxtxt.obj mxbol.obj cib71.obj cib72.obj cifm1.obj cifm2.obj cifm3.obj cidbx.obj cigiz.obj cirec.obj ciupd.obj citrm.obj ciupi.obj ciiso.obj ciutl.obj cifst.obj ciifu.obj cicgi.obj mys.obj ciutf8.obj  >>compilation1660.log

cd ..\projects64\mx

