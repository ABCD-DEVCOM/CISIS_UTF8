export LC_ALL=POSIX
mkdir utl2
mkdir utl2/linux64
mkdir utl2/linux64/isis1660
sh -x mxmake64.xsh utl2/linux64/isis1660 mx CIFFI=0 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE64_SOURCE=0
sh -x mxmake64.xsh utl2/linux64/isis1660 wxis CIFFI=0 LIND=0 LIND4=0 ISISXL=1 ISISXL512=0  SIXTY_FOUR=1 _FILE_OFFSET_BITS=00 _LARGEFILE64_SOURCE=0
<<<<<<< HEAD
#mkdir wxis
#kdir wxis/linux64
#mkdir wxis/linux64/isis1660
#cp utl2/linux64/isis1660/wxis wxis/linux64/isis1660
=======
mkdir wxis
mkdir wxis/linux64
mkdir wxis/linux64/isis1660
cp utl2/linux64/isis1660/wxis wxis/linux64/isis1660
>>>>>>> e661efdc39fdc305c9886453dd9952b3b4c2e48d
rm *.o
