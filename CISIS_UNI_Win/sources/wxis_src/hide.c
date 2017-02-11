/* ------------------------------------------------------------------ HIDE.C */

/* /////////////////////////////////////////////////////////////////////////

   [ Version 1.0 ]
   01.Mar.1999 - Hide/expose string.

   ///////////////////////////////////////////////////////////////////////// */

/* ----------------------------------------------------------- C HEADER FILE */
#include <string.h>
/* ------------------------------------------------------------ HEADER FILES */
#include "hide.h"

/* ------------------------------------------------------------------ define */
#define HIDE_OFFSET			16		/* hide character offset */
#define HIDE_MODULE			10		/* hide character offset */

/* =============================================================== hide_hide */
char *hide_hide(char *buff)		/* hide buffer */
{
/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	1.

   1.0 - 01.Mar.1999
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */
	int i;
   char *p;

	/* 1 */
   for (p = buff,i = 0; *p; p++,i++)
   	*p = *p - HIDE_OFFSET + (i %= HIDE_MODULE);

   return buff;
}
/* ============================================================= hide_expose */
char *hide_expose(char *buff)		/* hidden buffer */
{
/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	1.

   1.0 - 01.Mar.1999
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */
	int i;
   char *p;

	/* 1 */
   for (p = buff,i = 0; *p; p++,i++)
   	*p = *p + HIDE_OFFSET - (i %= HIDE_MODULE);

   return buff;
}

