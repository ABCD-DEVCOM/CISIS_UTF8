SET PATH=%PATH%;c:\Borland\BCC55\bin
cd ..\..\sources
rem -Q dropped in next line
rem Dropped -D in next line :     -DGCC=0  -DINCPROCX=1 -DINCPRECX=1 -DLINDLUX=0 -DPROCXSLT=0 -D_FILE_OFFSET_BITS=0 -D_LARGEFILE64_SOURCE=0
bcc32 -I"C:\Borland\BCC55\Include" -DUTF8=1 -DWWWISIS=1 -DCIFFI=0 -DLIND=0 -DCIWTF=1 -DISISXL=1  -c cidbx.c cirec.c cigiz.c citrm.c ciupd.c cifm1.c cifm2.c cifm3.c ciutl.c cib71.c cib72.c cifst.c ciifu.c ciupi.c ciifl.c cicgi.c ciiso.c mxaot.c mxrun.c mxrel.c mxtxt.c mxbol.c ifloadao.c mys.c ciutf8.c
cd wxis_src
rem -Q dropped in next line  DGCC=0  -DINCPROCX=1 -DINCPRECX=1 -DLINDLUX=0 -DPROCXSLT=0 -D_FILE_OFFSET_BITS=0 -D_LARGEFILE64_SOURCE=0
bcc32 -I"C:\Borland\BCC55\Include" -DUTF8=1 -DWWWISIS=1 -DCIFFI=0 -DLIND=0 -DCIWTF=1 -DISISXL=1 -c xis.c xis_exec.c xis_comp.c easyfc.c easyci.c arglist.c cgilist.c citpv.c freqlist.c hide.c hlfill.c cimsrt.c cixml.c
cd ..
rem -Q dropped in next line
bcc32 "C:\Borland\BCC55\Lib" -e..\projects\wxis\wxis1660utf8.exe cidbx.obj cirec.obj cigiz.obj citrm.obj ciupd.obj cifm1.obj cifm2.obj cifm3.obj ciutl.obj cib71.obj cib72.obj cifst.obj ciifu.obj ciupi.obj ciifl.obj cicgi.obj ciiso.obj mxaot.obj mxrun.obj mxrel.obj mxtxt.obj mxbol.obj ifloadao.obj mys.obj wxis_src\xis.obj wxis_src\xis_exec.obj wxis_src\xis_comp.obj wxis_src\easyfc.obj wxis_src\easyci.obj wxis_src\arglist.obj wxis_src\cgilist.obj wxis_src\citpv.obj wxis_src\freqlist.obj wxis_src\hide.obj wxis_src\hlfill.obj wxis_src\cimsrt.obj wxis_src\cixml.obj ciutf8.obj
del *.obj
cd ..\projects\wxis
del *.tds
