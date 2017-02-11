/* crumf2ux - convert PC master file to UNIX/Linux format
              crunchmf/AOT, 10/04/2001
*/
#include <stdio.h>
#include <string.h>
#include "cisis.h"
#include "cirun.h"

#define pc_SIZEOF_M0STRU        32
#define pc_LEADER               18
#define pc_MSNVSPLT             14 /* gdb .mst never split - 'til base */

#define ux_SIZEOF_M0STRU        32
#define ux_LEADER               20
#define ux_MSNVSPLT             16 /* gdb .mst never split - 'til base */

#define NOSW_20 0
#define NOSW_21 1
#define NOSW_40 0
#define NOSW_41 1
#define NOSW_42 2
#define NOSW_43 3

#define SWAP_20 1
#define SWAP_21 0
#define SWAP_40 3
#define SWAP_41 2
#define SWAP_42 1
#define SWAP_43 0

int target_SIZEOF_M0STRU;
int target_LEADER;
int target_MSNVSPLT;

char *movtmp;
int alignment;
int mv20,mv21,mv40,mv41,mv42,mv43;
int xalign;

#define mov2(moved,movp,source)                            \
        movtmp  = (char *)&(source);            \
        if (alignment >= 2) if ((xalign=moved%2) != 0) while (xalign--) { *movp++ = '\0'; moved++; } \
        *movp++ = movtmp[mv20];                \
        *movp++ = movtmp[mv21];                \
        moved+=2;
#define mov4(moved,movp,source)                            \
        if (alignment >= 4) if ((xalign=moved%4) != 0) while (xalign--) { *movp++ = '\0'; moved++; } \
        movtmp  = (char *)&(source);            \
        *movp++ = movtmp[mv40];                \
        *movp++ = movtmp[mv41];                \
        *movp++ = movtmp[mv42];                \
        *movp++ = movtmp[mv43];                \
        moved+=4;
#define movx(sourcep,len)                       \
        memmove(movp,sourcep,(size_t)len);       \
        movp+=len;                              \
        moved+=len;
/*
#define mov2(moved,movp,source)                            \
        movtmp  = (char *)&(source);            \
        swab(movtmp,movp,2); movp+=2;           \
        moved+=2;
*/

#if ANSI
void putuxmst(LONGX mfn, UWORD reclen);
void putuxxrf(LONGX mfn, LONGX comb, int comp);
void enduxmst(UWORD reclen);
#else
void putuxmst();
void putuxxrf();
void enduxmst();
#endif

int xrf_fd;
char *xrf_buffer;
LONGX xrf_lastmfn;
int mst_fd;
char *mst_buffer,*mst_record;
LONGX mst_nxtmfb;
int mst_nxtmfp;
UWORD mst_left,mst_type;

void main(argc,argv)
int argc;
char *argv[];
{
    RECSTRU *recp; /* mandatory for defines REC RDB MF0 MFR DIR, FIELDP */
    char *dbnp,*uxdbnp;
    LONGX irec,mfn;
    UWORD mfrl,base,datalen;
    DIRSTRU *dirp;
    int xdir;
    char *p,line[BUFSIZ];
    LONGX count1,count2;
    int argnext=1;
    int parmtrace=0;
    LONGX parmfrom,parmto,parmtell,parmloop,parmcount;
    /* int zero=0; */
    char *movp;
    UWORD moved;

/*
#if PC || VAX || UNISYSCPU || INTELCPU
#define SWAPPED     1
#endif
*/
#define TARGET_pc     0
#define TARGET_linux  1
#define TARGET_hp-ux  2
#define TARGET_sun    3
#define TARGET_alpha  4
#define TARGET_vax    5
#define TARGET_unisys 6
#define TARGET_mpe    7
#define TARGET_cdc    8
                         /* 0    1       2       3     4       5     6        7     8   */
    char *target_id[]   = {"pc","linux","hpux","sun","alpha","vax","unisys","mpe","cdc",NULL};
    int target_align[]  = { 1,   4,      4,      4,    4,      1,    4,       4,    4,  0 };
    int target_swapped[]= { 1,   1,      0,      0,    1,      1,    1,       0,    0,  0 };
    int i;

#if PC
    int xtarget=TARGET_linux;
#else
    int xtarget=TARGET_pc;
#endif

    int xorigin=TARGET_alpha;
#if PC
    xorigin=TARGET_pc;
#endif
#if UNIX
#if INTELCPU
    xorigin=TARGET_linux;
#endif
#endif
#if BRME
    xorigin=TARGET_hp-ux;
#endif
#if SUN
    xorigin=TARGET_sun;
#endif
#if VAX
    xorigin=TARGET_vax;
#endif
#if UNISYSCPU
    xorigin=TARGET_unisys;
#endif
#if MPE
    xorigin=TARGET_mpe;
#endif
#if CDCS4320
    xorigin=TARGET_cds;
#endif
/*
#define PC          0
#define VAX         0
#define MPE         0
#define UNIX        0
#define SUN         0
#define UNISYSCPU   0
#define INTELCPU    0
#define BRME        0
#define CDCS4320    0
*/

    if (argc == 2 && strcmp(argv[1],"what") == 0) {
        printf("%s",cicopyr("?Utility CRUMF2UX"));
        printf("\n");
        exit(0);
    }
    if (argc < 3) {
        printf("%s",cicopyr("Utility CRUMF2UX"));
        printf("\n");
        printf("crumf2ux <dbn> <target_dbn> [<option> [...]] \n");
        printf(" \n");
        printf("options: \n");
        printf("\n");
        printf("   {from|to|loop|count|tell}=<n> \n");
        printf("\n");
        printf("   target=<platform> \n");
        printf("\n");
        printf("platforms: \n");
        printf("\n");
        printf("   %s (default for %s) \n",target_id[xtarget],target_id[xorigin]);
        for (i=0; target_id[i]; i++)
          if (i != xtarget && i != xorigin) printf("   %s \n",target_id[i]);
/*
        printf(" target={%s",target_id[xtarget]);
        for (i=0; target_id[i]; i++)
          if (i != xtarget && i != xorigin) printf("|%s",target_id[i]);
        printf("} \n");
        printf(" \n");
        printf("default: %s \n",target_id[xtarget]);
*/
        printf(" \n");
        exit(1);
    }

    /* get positional parms */
    dbnp=argv[argnext++];
    uxdbnp=argv[argnext++];

    /* get optional parms */
    parmfrom=1L; parmto=9999999L; parmtell=0L; parmloop=1L;

    if (strcmp(dbnp,"null")) parmcount=LONGX_MAX; else parmcount=0L;

    for (; argnext < argc; ) {
        p=argv[argnext++];
        if (strncmp(p,"from?",5) == 0 || strncmp(p,"from=",5) == 0) {
            if (sscanf(p+5,"%"_LD_,&parmfrom) != 1) fatal(p);
            continue;
        }
	     if (strncmp(p,"to?",3) == 0 || strncmp(p,"to=",3) == 0) {
	         if (sscanf(p+3,"%"_LD_,&parmto) != 1) fatal(p);
            continue;
        }
        if (strncmp(p,"count?",6) == 0 || strncmp(p,"count=",6) == 0) {
            if (sscanf(p+6,"%"_LD_,&parmcount) != 1)
                fatal(p);
            continue;
        }
        if (strncmp(p,"loop?",5) == 0 || strncmp(p,"loop=",5) == 0) {
            if (sscanf(p+5,"%"_LD_,&parmloop) != 1)
                fatal(p);
            continue;
        }
        if (strncmp(p,"tell?",5) == 0 || strncmp(p,"tell=",5) == 0) {
            if (sscanf(p+5,"%"_LD_,&parmtell) != 1) fatal(p);
            continue;
        }
        if (strcmp(p,"trace?all") == 0|| strcmp(p,"trace=all") == 0) {
	         parmtrace=dbxtrace=rectrace=1;
            continue;
        }
        if (strcmp(p,"trace") == 0) {
            parmtrace=1;
            continue;
        }
        if (strncmp(p,"target?",7) == 0 || strncmp(p,"target=",7) == 0) {
            int found=0;
            for (xtarget=0; target_id[xtarget]; xtarget++) {
                if (strcmp(p+7,target_id[xtarget])) continue;
                found=1; break;
            }
            if (!found) fatal(p);
            continue;
        }
        fatal(p);
    }

    /* setup processing */
    alignment=target_align[xtarget];

    if (xtarget == TARGET_pc) {
        target_SIZEOF_M0STRU=pc_SIZEOF_M0STRU;
        target_LEADER=pc_LEADER;
        target_MSNVSPLT=pc_MSNVSPLT;
    } else {
        target_SIZEOF_M0STRU=ux_SIZEOF_M0STRU;
        target_LEADER=ux_LEADER;
        target_MSNVSPLT=ux_MSNVSPLT;
    }

    mv20=NOSW_20;
    mv21=NOSW_21;
    mv40=NOSW_40;
    mv41=NOSW_41;
    mv42=NOSW_42;
    mv43=NOSW_43;
    if (target_swapped[xtarget] != target_swapped[xorigin]) {
        mv20=SWAP_20;
        mv21=SWAP_21;
        mv40=SWAP_40;
        mv41=SWAP_41;
        mv42=SWAP_42;
        mv43=SWAP_43;
    }

    /* get control record */
    RECORD(irec=nrecs,dbnp,0L);
    if (parmtrace) prtcontrol(recp,dbnp);

    /* create .xrf and allocate putuxxrf() output buffer */
    strcpy(line,uxdbnp);
    strcat(line,xx1extp);
    p=dbxopenc(uxdbnp,line,&xrf_fd,NULL,NULL,1,0); /*..force create= */
    if (xrf_fd <= 0) fatal(line);
    if (parmtrace) printf("+++ %s=%d\n",p,xrf_fd);
    xrf_buffer=(char *)ALLOC((ALLOPARM)XRBSIZ);
    if (xrf_buffer == (char *)ALLONULL) fatal("ALLOC/xrf_buffer");

    /* create .mst and allocate putuxmst() output buffer */
    strcpy(line,uxdbnp);
    strcat(line,mx1extp);
    p=dbxopenc(uxdbnp,line,&mst_fd,NULL,NULL,1,0); /*..force create= */
    if (mst_fd <= 0) fatal(line);
    if (parmtrace) printf("+++ %s=%d\n",p,mst_fd);
    mst_buffer=(char *)ALLOC((ALLOPARM)MSBSIZ);
    if (mst_buffer == (char *)ALLONULL) fatal("ALLOC/mst_buffer");

    /* initialize putuxxrf() */
    xrf_lastmfn=MF0nxtmfn-1;
    if (parmto < xrf_lastmfn) xrf_lastmfn=parmto;
    /* initialize putuxmst() */
    mst_nxtmfb=1L;
    mst_nxtmfp=1;
    mst_left=MSBSIZ;
    mst_type=MF0mftype;

    /* allocate processing buffer */
    mst_record=(char *)ALLOC((ALLOPARM)MAXMFRL);
    if (mst_record == (char *)ALLONULL) fatal("ALLOC/mst_record");

    /* initialize control record */
    movp=mst_record;
    moved=target_SIZEOF_M0STRU+target_SIZEOF_M0STRU; /* gdb */
    memset(movp,0x00,moved);
    putuxmst(0L,moved);
    for (mfn=1L; mfn < parmfrom; mfn++) {
        putuxxrf(mfn,(-1L),0);                          /* PDEL pointer */
    }

    /* convert mf records */
    for (count1=count2=0L, mfn=parmfrom; mfn <= parmto; mfn+=parmloop) {
        RECORD(irec,dbnp,mfn);
        if (RECrc == RCEOF) break;
        if (count1 >= parmcount) break;
        count1++;
        if (RECrc != RCNORMAL) {
            putuxxrf(mfn,(-1L),0);                      /* PDEL pointer */
	         continue;
        }
        count2++;
        base=target_LEADER+MFRnvf*sizeof(DIRSTRU);
        datalen=0;
        for (dirp=MFRdir, xdir=MFRnvf; xdir--; dirp++) datalen+=dirp->len;
        mfrl=base+datalen;
        if (mfrl & 0x01) mfrl++;        /* gdb always an even number */
        MFRmfbwb=0L;
        MFRmfbwp=0;
        movp=mst_record; moved=0;
        mov4(moved,movp,MFRmfn);
        mov2(moved,movp,mfrl);
        /* mov2(moved,movp,zero); /* align - in putuxmst.. */
        mov4(moved,movp,MFRmfbwb);
        mov2(moved,movp,MFRmfbwp);
        mov2(moved,movp,base);
        mov2(moved,movp,MFRnvf);
        mov2(moved,movp,MFRstatus);
        for (dirp=MFRdir, xdir=0; xdir < MFRnvf; xdir++, dirp++) {
            mov2(moved,movp,dirp->tag);
            mov2(moved,movp,dirp->pos);
            mov2(moved,movp,dirp->len);
        }
        movx(MFX+MFRbase,datalen);
        if (moved & 0x01) {
            *movp=' '; moved++;         /* gdb always an even number */
        }
        putuxmst(mfn,moved);

        if (parmtell)
            if (count1 % parmtell == 0)
                fprintf(stderr,"+++ %"_LD_"/%"_LD_" \n",count1,count2);
    }

    /* update control record */
    RECORD(irec,dbnp,0L);
    MF0nxtmfn=xrf_lastmfn+1;
    MF0nxtmfb=mst_nxtmfb;
    MF0nxtmfp=mst_nxtmfp;
    MF0reccnt=MF0mfcxx1=MF0mfcxx2=MF0mfcxx3=0;
    movp=mst_record; moved=0;
    mov4(moved,movp,MF0ctlmfn);
    mov4(moved,movp,MF0nxtmfn);
    mov4(moved,movp,MF0nxtmfb);
    mov2(moved,movp,MF0nxtmfp);  /* bug */
    mov2(moved,movp,MF0mftype);
    mov4(moved,movp,MF0reccnt);
    mov4(moved,movp,MF0mfcxx1);
    mov4(moved,movp,MF0mfcxx2);
    mov4(moved,movp,MF0mfcxx3);
    enduxmst(moved);
    if (parmtell)
        if (count1 % parmtell == 0) ; else
            fprintf(stderr,"+++ %"_LD_"/%"_LD_" \n",count1,count2);

    exit(0);
}

void putuxmst(mfn,reclen)
LONGX mfn;
UWORD reclen;
{
    char *p;
    int n;
#if MSTTRACE
    int loop;
    for (p=mst_record, loop=0; loop<reclen; p++) {
        printf("%02x ",*p);
        if (++loop%16 == 0) printf("\n");
    }
    printf("\n");
#endif
    if (mst_type == MSMFTMSG) {
        n = reclen % MSBSIZ;
        if (n) {
            n=MSBSIZ-n;
            memset(mst_record+reclen,0x00,n); reclen+=n;
        }
    }
    if (mst_left < target_MSNVSPLT) {
        memset(&mst_buffer[MSBSIZ-mst_left],0x00,mst_left);
        if (CIWRITE(mst_fd,mst_buffer,MSBSIZ) < MSBSIZ) fatal("putuxmst/write");
        mst_nxtmfb++; mst_nxtmfp=1;
        mst_left=MSBSIZ;
    }
    putuxxrf(mfn,mst_nxtmfb,mst_nxtmfp-1);
    for (p=mst_record; reclen; ) {
        if (reclen <= mst_left) {
            memmove(&mst_buffer[MSBSIZ-mst_left],p,(size_t)reclen);
            mst_left-=reclen;
            mst_nxtmfp+=reclen;
            break;
        }
        memmove(&mst_buffer[MSBSIZ-mst_left],p,mst_left);
        if (CIWRITE(mst_fd,mst_buffer,MSBSIZ) < MSBSIZ) fatal("putuxmst/write");
        reclen-=mst_left;
        p+=mst_left;
        mst_left=MSBSIZ;
        mst_nxtmfb++; mst_nxtmfp=1;
    }
}
void enduxmst(reclen)
UWORD reclen;
{
#if MSTTRACE
    char *p;
    int loop;
    for (p=mst_record, loop=0; loop<reclen; p++) {
        printf("%02x ",*p);
        if (++loop%16 == 0) printf("\n");
    }
    printf("\n");
#endif
    if (mst_left < MSBSIZ) {
        memset(&mst_buffer[MSBSIZ-mst_left],0x00,mst_left);
        if (CIWRITE(mst_fd,mst_buffer,MSBSIZ) < MSBSIZ) fatal("enduxmst/write");
    }
    putuxxrf(-1L,0L,0);
    if (reclen) {
        if (LSEEK64(mst_fd,SEEK_SET,0L) != 0L) fatal("enduxmst/seek");
        if (CIWRITE(mst_fd,mst_record,reclen) < reclen) fatal("enduxmst/write");
    }
}
void putuxxrf(mfn,comb,comp)
LONGX mfn;
LONGX comb;
int comp;
{
    static XRSTRU *xrxp;
    static LONGX xrf_block,xrf_lastblock;
    static int xrf_lastidx;
    static int xrf_towrit=0L;
    XRPTR pointer,xrftiv;
    int thisidx,n;
    XRPOS thispos;
    char x[4];
    char *movp;
    UWORD moved;

    if (mfn < 0L) if (xrf_towrit) {
        for (moved=0, movp=xrf_buffer, n=XRBSIZ; n; n-=4) {memmove(x,movp,4); mov4(moved,movp,x[0]);}
        if (CIWRITE(xrf_fd,xrf_buffer,XRBSIZ) != XRBSIZ) fatal("putuxxrf/write");
        if (xrxp->xrxrpos < 0) return;

        xrxp->xrxrpos = -xrf_lastblock;
        xrftiv = (0)*XRXDIVIDE + (0);                   /* EOF pointer */
        for (n=0; n < XRMAXTIV; ) xrxp->xrmfptr[n++]=xrftiv;
        for (moved=0, movp=xrf_buffer, n=XRBSIZ; n; n-=4) {memmove(x,movp,4); mov4(moved,movp,x[0]);}
        if (CIWRITE(xrf_fd,xrf_buffer,XRBSIZ) != XRBSIZ) fatal("putuxxrf/write");
        return;
    }
    if (mfn == 0) {
        if (mfn + XRBSIZ % 4) fatal("putuxxrf/XRBSIZ");
        xrxp=(XRSTRU *)xrf_buffer;
        xrf_block=0L;
        xrf_lastblock=(xrf_lastmfn+XRMAXTV1)/XRMAXTIV;
        if (xrf_lastmfn%XRMAXTIV == 0) xrf_lastblock++; /* 127 */
        xrf_lastidx=0;

        xrxp->xrxrpos = ++xrf_block;
        if (xrf_block == xrf_lastblock) xrxp->xrxrpos = -xrf_block;
        xrftiv = (0)*XRXDIVIDE + (0);                   /* EOF pointer */
        for (n=0; n < XRMAXTIV; ) xrxp->xrmfptr[n++]=xrftiv;
        xrf_towrit=1;
        return;
    }
    thispos=(mfn+XRMAXTV1)/XRMAXTIV;
    thisidx=(mfn-1)%XRMAXTIV;
    pointer = comb * XRXDIVIDE + comp;
    if (thispos < xrf_block) fatal("putuxxrf/thispos");
    if (thispos == xrf_block) {
        xrftiv=(-1)*XRXDIVIDE + (0);                    /* PDEL pointer */
        for (n=xrf_lastidx+1; n<thisidx; n++) xrxp->xrmfptr[n] = xrftiv;
        xrxp->xrmfptr[xrf_lastidx=thisidx] = pointer;
        xrf_towrit=1;
        return;
    }
    
    /* thispos > xrf_block */
    for (moved=0, movp=xrf_buffer, n=XRBSIZ; n; n-=4) {memmove(x,movp,4); mov4(moved,movp,x[0]);}
    if (CIWRITE(xrf_fd,xrf_buffer,XRBSIZ) != XRBSIZ) fatal("putuxxrf/write");
    xrftiv=(-1)*XRXDIVIDE + (0);                        /* PDEL pointer */
    for (n=0; n < XRMAXTIV; ) xrxp->xrmfptr[n++]=xrftiv;
    while (++xrf_block < thispos) {
        xrxp->xrxrpos = xrf_block;
        if (xrf_block == xrf_lastblock) fatal("putuxxrf/lastblock");
        for (moved=0, movp=xrf_buffer, n=XRBSIZ; n; n-=4) {memmove(x,movp,4); mov4(moved,movp,x[0]);}
        if (CIWRITE(xrf_fd,xrf_buffer,XRBSIZ) != XRBSIZ) fatal("putuxxrf/write");
    }
    xrxp->xrxrpos = xrf_block;
    if (xrf_block == xrf_lastblock) xrxp->xrxrpos = -xrf_block;
    xrxp->xrmfptr[xrf_lastidx=thisidx] = pointer;
    xrftiv= (0)*XRXDIVIDE + (0);                        /* EOF pointer */
    for (n=thisidx+1; n<XRMAXTIV; n++) xrxp->xrmfptr[n] = xrftiv;
    xrf_towrit=1;
    return;
}
