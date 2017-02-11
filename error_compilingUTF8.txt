In file included from wtrun.c:262:0,
                 from ciupd.c:1433:
w2.c: In function ‘trigcoll’:
w2.c:223:13: error: ‘isisuctab’ undeclared (first use in this function)
     memmove(isisuctab,ansiuctab,256/*sizeof(ansiuctab)*/);
             ^
w2.c:223:13: note: each undeclared identifier is reported only once for each function it appears in

w2.c:223:23: error: ‘ansiuctab’ undeclared (first use in this function)
     memmove(isisuctab,ansiuctab,256/*sizeof(ansiuctab)*/);
                       ^
w2.c:224:23: error: ‘ansiactab’ undeclared (first use in this function)
     for (isiswctot=0; ansiactab[isiswctot]; isiswctot=isiswctot+1) isiswctab[ansiactab[isiswctot]]=1;       
                       ^
w2.c:224:68: error: ‘isiswctab’ undeclared (first use in this function)
     for (isiswctot=0; ansiactab[isiswctot]; isiswctot=isiswctot+1) isiswctab[ansiactab[isiswctot]]=1;       

