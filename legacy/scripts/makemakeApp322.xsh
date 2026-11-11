export LC_ALL=POSIX

echo crunchif.mak  > xls
echo crunchmf.mak >> xls
echo ctlmfn.mak   >> xls
echo i2id.mak     >> xls
echo id2i.mak     >> xls
echo ifkeys.mak   >> xls
echo ifload.mak   >> xls
echo ifmerge.mak  >> xls
echo ifupd.mak    >> xls
echo mkiy0.mak    >> xls
echo mkxrf.mak    >> xls
echo msrt.mak     >> xls
echo mx.mak       >> xls
echo mxcp.mak     >> xls
echo mxf0.mak     >> xls
echo mxtb.mak     >> xls
echo mys.mak      >> xls
echo retag.mak    >> xls
echo wxis.mak     >> xls

echo export LC_ALL=POSIX    >xmk.xsh
echo mkdir  utl            >>xmk.xsh
echo mkdir  utl/linux32    >>xmk.xsh

#echo mkdir utl/linux32/isis       >mkisis_32.xsh
echo mkdir utl/linux32/isis1660   >mkisis1660_32.xsh
#echo mkdir utl/linux32/isisG      >mkisisG_32.xsh
#echo mkdir utl/linux32/lind       >mklind_32.xsh
#echo mkdir utl/linux32/lindG4     >mklindG4_32.xsh
#echo mkdir utl/linux32/lind512    >mklind512_32.xsh
#echo mkdir utl/linux32/lind512G4  >mklind512G4_32.xsh
#echo mkdir utl/linux32/ffi        >mkffi_32.xsh
#echo mkdir utl/linux32/ffiG4      >mkffiG4_32.xsh
#echo mkdir utl/linux32/ffi512     >mkffi512_32.xsh
#echo mkdir utl/linux32/ffi512G4   >mkffi512G4_32.xsh
#echo mkdir utl/linux32/ffi1660    >mkffi1660_32.xsh
#echo mkdir utl/linux32/BigIsis    >mkBigIsis_32.xsh

#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/isis     'left(v1,size(v1)-4)' CIFFI=0 LIND=0 LIND4=0 ISISXL=0 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE32_SOURCE=0'/" lw=0 now >>mkisis_32.xsh
./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/isis1660 'left(v1,size(v1)-4)' CIFFI=0 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE32_SOURCE=0'/" lw=0 now >>mkisis1660_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/isisG    'left(v1,size(v1)-4)' CIFFI=0 LIND=0 LIND4=0 ISISXL=0 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=32 _LARGEFILE32_SOURCE=1'/" lw=0 now >>mkisisG_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/lind     'left(v1,size(v1)-4)' CIFFI=0 LIND=1 LIND4=0 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE32_SOURCE=0'/" lw=0 now >>mklind_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/lindG4   'left(v1,size(v1)-4)' CIFFI=0 LIND=1 LIND4=1 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=32 _LARGEFILE32_SOURCE=1'/" lw=0 now >>mklindG4_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/lind512  'left(v1,size(v1)-4)' CIFFI=0 LIND=1 LIND4=0 ISISXL=1 ISISXL512=1  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE32_SOURCE=0'/" lw=0 now >>mklind512_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/lind512G4  'left(v1,size(v1)-4)' CIFFI=0 LIND=1 LIND4=1 ISISXL=1 ISISXL512=1  SIXTY_FOUR=1 _FILE_OFFSET_BITS=32 _LARGEFILE32_SOURCE=1'/" lw=0 now >>mklind512G4_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/ffi      'left(v1,size(v1)-4)' CIFFI=1 LIND=1 LIND4=0 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE32_SOURCE=0'/" lw=0 now >>mkffi_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/ffiG4    'left(v1,size(v1)-4)' CIFFI=1 LIND=1 LIND4=1 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=32 _LARGEFILE32_SOURCE=1'/" lw=0 now >>mkffiG4_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/ffi512   'left(v1,size(v1)-4)' CIFFI=1 LIND=1 LIND4=0 ISISXL=1 ISISXL512=1  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE32_SOURCE=0'/" lw=0 now >>mkffi512_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/ffi512G4 'left(v1,size(v1)-4)' CIFFI=1 LIND=1 LIND4=1 ISISXL=1 ISISXL512=1  SIXTY_FOUR=1 _FILE_OFFSET_BITS=32 _LARGEFILE32_SOURCE=1'/" lw=0 now >>mkffi512G4_32.xsh
#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/ffi1660  'left(v1,size(v1)-4)' CIFFI=1 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE32_SOURCE=0'/" lw=0 now >>mkffi1660_32.xsh

#./mx seq=xls "pft='sh -x mxmake32.xsh utl/linux32/BigIsis    'left(v1,size(v1)-4)' CIFFI=1 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0 SIXTY_FOUR=1  _FILE_OFFSET_BITS=32 _LARGEFILE32_SOURCE=1 SUPERISIS=1'/" lw=0 now >>mkBigIsis_32.xsh


#cat           mkisis_32.xsh       >>xmk.xsh
cat           mkisis1660_32.xsh   >>xmk.xsh
#cat           mkisisG_32.xsh      >>xmk.xsh
#cat           mklind_32.xsh       >>xmk.xsh
#cat           mklindG4_32.xsh     >>xmk.xsh
#cat           mklind512_32.xsh    >>xmk.xsh
#cat           mklind512G4_32.xsh  >>xmk.xsh
#cat           mkffi_32.xsh        >>xmk.xsh
#cat           mkffiG4_32.xsh      >>xmk.xsh
#cat           mkffi512_32.xsh     >>xmk.xsh
#cat           mkffi512G4_32.xsh   >>xmk.xsh
#cat           mkffi1660_32.xsh    >>xmk.xsh

#cat           mkBigIsis_32.xsh   >>xmk.xsh

#echo          cp utl/linux32/lindG4/crunchmf utl/linux32/isis            >>xmk.xsh
#echo          cp utl/linux32/lindG4/crunchmf utl/linux32/isis1660        >>xmk.xsh
#echo          cp utl/linux32/lindG4/crunchmf utl/linux32/lind            >>xmk.xsh
#echo          cp utl/linux32/lindG4/crunchmf utl/linux32/lind512         >>xmk.xsh

#echo          cp utl/linux32/ffiG4/crunchmf utl/linux32/ffi              >>xmk.xsh
#echo          cp utl/linux32/ffiG4/crunchmf utl/linux32/ffi512           >>xmk.xsh
#echo          cp utl/linux32/ffiG4/crunchmf utl/linux32/ffi1660          >>xmk.xsh

#echo          mv utl/linux32/lind/ifload utl/linux32/lind/iflind             >>xmk.xsh
#echo          mv utl/linux32/lindG4/ifload utl/linux32/lindG4/iflind         >>xmk.xsh
#echo          mv utl/linux32/lind512/ifload utl/linux32/lind512/iflind       >>xmk.xsh
#echo          mv utl/linux32/lind512G4/ifload utl/linux32/lind512G4/iflind   >>xmk.xsh
#echo          mv utl/linux32/ffi/ifload utl/linux32/ffi/iflind               >>xmk.xsh
#echo          mv utl/linux32/ffiG4/ifload utl/linux32/ffiG4/iflind           >>xmk.xsh
#echo          mv utl/linux32/ffi512/ifload utl/linux32/ffi512/iflind         >>xmk.xsh
#echo          mv utl/linux32/ffi512G4/ifload utl/linux32/ffi512G4/iflind     >>xmk.xsh
#echo          mv utl/linux32/ffi1660/ifload utl/linux32/ffi1660/iflind       >>xmk.xsh

#echo          rm utl/linux32/lind/ifupd       >>xmk.xsh
#echo          rm utl/linux32/lindG4/ifupd     >>xmk.xsh
#echo          rm utl/linux32/lind512/ifupd    >>xmk.xsh
#echo          rm utl/linux32/lind512G4/ifupd  >>xmk.xsh
#echo          rm utl/linux32/ffi/ifupd        >>xmk.xsh
#echo          rm utl/linux32/ffiG4/ifupd      >>xmk.xsh
#echo          rm utl/linux32/ffi512/ifupd     >>xmk.xsh
#echo          rm utl/linux32/ffi512G4/ifupd   >>xmk.xsh

#echo          mkdir wxis                      >>xmk.xsh
#echo          mkdir wxis/linux32              >>xmk.xsh
#echo          mkdir wxis/linux32/isis         >>xmk.xsh
#echo          mkdir wxis/linux32/isis1660     >>xmk.xsh
#echo          mkdir wxis/linux32/isisG        >>xmk.xsh
#echo          mkdir wxis/linux32/lind         >>xmk.xsh
#echo          mkdir wxis/linux32/lindG4       >>xmk.xsh
#echo          mkdir wxis/linux32/lind512      >>xmk.xsh
#echo          mkdir wxis/linux32/lind512G4    >>xmk.xsh
#echo          mkdir wxis/linux32/ffi          >>xmk.xsh
#echo          mkdir wxis/linux32/ffiG4        >>xmk.xsh
#echo          mkdir wxis/linux32/ffi512       >>xmk.xsh
#echo          mkdir wxis/linux32/ffi512G4     >>xmk.xsh
#echo          mkdir wxis/linux32/ffi1660      >>xmk.xsh
#echo          mkdir wxis/linux32/BigIsis      >>xmk.xsh

#echo          cp utl/linux32/isis/wxis wxis/linux32/isis            >>xmk.xsh
echo          cp utl/linux32/isis1660/wxis wxis/linux32/isis1660    >>xmk.xsh
#echo          cp utl/linux32/isisG/wxis wxis/linux32/isisG          >>xmk.xsh
#echo          cp utl/linux32/lind/wxis wxis/linux32/lind            >>xmk.xsh
#echo          cp utl/linux32/lindG4/wxis wxis/linux32/lindG4        >>xmk.xsh
#echo          cp utl/linux32/lind512/wxis wxis/linux32/lind512      >>xmk.xsh
#echo          cp utl/linux32/lind512G4/wxis wxis/linux32/lind512G4  >>xmk.xsh
#echo          cp utl/linux32/ffi/wxis wxis/linux32/ffi              >>xmk.xsh
#echo          cp utl/linux32/ffiG4/wxis wxis/linux32/ffiG4          >>xmk.xsh
#echo          cp utl/linux32/ffi512/wxis wxis/linux32/ffi512        >>xmk.xsh
#echo          cp utl/linux32/ffi512G4/wxis wxis/linux32/ffi512G4    >>xmk.xsh
#echo          cp utl/linux32/ffi1660/wxis wxis/linux32/ffi1660      >>xmk.xsh
echo          cp utl/linux32/BigIsis/wxis wxis/linux32/BigIsis      >>xmk.xsh

echo "nohup time sh -x xmk.xsh &"
nohup time sh -x xmk.xsh &

echo "compilation Isis1660/BigISIS 32 bits finished !!!"
exit
