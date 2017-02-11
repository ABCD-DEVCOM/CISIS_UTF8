// INCLUDES STANDARD C
#include <stdio.h>
#include <ctype.h>
#include <string.h>

// INCLUDES CISIS
#include "cisis.h"

// GLOBAL VARIABLES
unsigned char * file_header_utf8 = "\xEF\xBB\xBF";		// UTF-8 file identification header

#if UTF8
// FUNCTIONS

// ----------------------------------------------------------------------------
// Count the string length in utf-8 characters (not in bytes)
size_t	strlen_utf8
(
	unsigned char * str				// the string to be counted
)
{
    size_t			length	= 0;	// length in utf-8 characters
    unsigned char *	p		= str;	// pointer to go byte by byte

    while ( *p != 0 ) 
	{
		// character UTF-8 with only 1 byte
        if ( (*p & 0x80) == 0 )		 // 1000 0000
		{
            p++;
        }
		// character UTF-8 with 2 bytes
		else if ( (*p >> 5) == 6 )	 // 1100 0000
		{
            p += 2;
        }
		// character UTF-8 with 3 bytes
		else if ( (*p >> 4) == 14 )	 // 1110 0000
		{
            p += 3;
        }
		// character UTF-8 with 4 bytes
		else if ( (*p >> 3) == 30 )	 // 1111 0000
		{
            p += 4;
        } 
		// character UTF-8 not recognized
		else
		{
            //fatal("strlen_utf8/UTF-8 character not recognized");
            p++;
        }
		length++;
    }

	// return the utf-8 length    
    return length;
}

// ----------------------------------------------------------------------------
// Skip a number of utf-8 characters (not bytes)
unsigned char *	skipchar_utf8
(
	unsigned char *	str,			// the character pointer to be skipped
	size_t			qtt				// quantity of utf-8 characters to be skipped
)
{
    size_t			count_skip	= 0;	// count the quantity of characters skipped
    unsigned char *	p			= str;	// pointer to go byte by byte

    while ( (*p != 0) && (count_skip < qtt) )
	{
		// character UTF-8 with only 1 byte
        if ( (*p & 0x80) == 0 )		 // 1000 0000
		{
            p++;
        }
		// character UTF-8 with 2 bytes
		else if ( (*p >> 5) == 6 )	 // 1100 0000
		{
            p += 2;
        }
		// character UTF-8 with 3 bytes
		else if ( (*p >> 4) == 14 )	 // 1110 0000
		{
            p += 3;
        }
		// character UTF-8 with 4 bytes
		else if ( (*p >> 3) == 30 )	 // 1111 0000
		{
            p += 4;
        } 
		// character UTF-8 not recognized
		else
		{
            //fatal("strlen_utf8/UTF-8 character not recognized");
            p++;
        }
        count_skip++;
    }
    
	// return the new position
    return p;
}

// ----------------------------------------------------------------------------
// Get the previuos utf8 character in a string
unsigned char *	previous_char_utf8
(
	size_t			pos,				// byte position in the string
	unsigned char *	str					// current position
)
{
	size_t			reverse_limit = 4;	// the previous char is at maximun this backward byte distance
	size_t			i;					// count
	unsigned char *	revp;				// reverse string pointer
	unsigned char *	nextp;				// next character

	// do not go backward the minimum
	if ( pos < reverse_limit ) 
	{
		reverse_limit = pos;		
	}
	
	// search for the previous utf-8 character
	for ( i = reverse_limit, revp = str - i; i; i--, revp++ )
	{
		nextp = skipchar_utf8(revp,1);	// next utf-8 character
		if ( nextp > str )	// it is the middle of the utf-8 character, it is not the begin of a utf-8 character
		{
			// no previous utf-8 character
			return 0;
		}
		if ( nextp == str )	// found
		{
			// return previous character pointer
			return revp;
		}
	}
	
	// no previous utf-8 character
	return 0;
}

// ----------------------------------------------------------------------------
// Find the corresponding utf-8 upper case character
STRUCT_ISISUCTAB_UTF8 *	uppercase_utf8_character
(
	STRUCT_ISISUCTAB_UTF8	uctab_utf8[],	// utf-8 upper case table
	unsigned char *			pCharacter		// pointer to the utf-8 character
)
{
	int				line;					// table line
	int				column;					// line column
	unsigned char * q;

	// all table lines
	for ( line = 0; uctab_utf8[line].lower[0]; line++ )
	{
		q = pCharacter;			// character pointer

		// all columns
		for ( column = 0; uctab_utf8[line].lower[column]; column++, q++ )
		{
			// the table is in ascending order, greater value means not found
			if ( *q < uctab_utf8[line].lower[column] )
			{
				// return not found
				return 0;
			}

			// found?
			if ( *q == uctab_utf8[line].lower[column] )
			{
				// if it is the last column, indicates found
				if ( uctab_utf8[line].lower[column + 1] == 0 )
				{
					// return pointer to the utf-8 upper case table character line
					return &uctab_utf8[line];
				}
				
				// next column
				continue;
			}
			
			// next line
			break;
		}
	}
	
	// return not found
	return 0;
}

// ----------------------------------------------------------------------------
// Convert a string to utf-8 upper case limited by quantity of utf-8 characters
unsigned char *	uppercase_utf8_length
(
	STRUCT_ISISUCTAB_UTF8	uctab_utf8[],	// utf-8 upper case table
	unsigned char *			str,			// string to be converted to upper case
	size_t					qtt				// quantity of bytes
)
{
	unsigned char * 		p;				// pointer to each source string character
	unsigned char * 		pTarget;		// place to store upper case string
	unsigned char * 		q;				// pointer to each utf-8 upper case character in table
	STRUCT_ISISUCTAB_UTF8 * uctab_line;		// pointer to the upper case table line
	
	// all characters
	for ( p = str, pTarget = str; *p && qtt > 0; )
	{		
		// get the table line of corresponding utf-8 character
		uctab_line = uppercase_utf8_character(uctab_utf8,p);
		
		if ( uctab_line )	// found
		{
			// copy upper case utf-8 character
			for ( q = uctab_line->upper; *q; pTarget++, q++ )
			{
				*pTarget = *q;
				qtt--;
			}
			p += strlen(uctab_line->lower);		// next source character
		}
		else				// not found
		{
			// copy original
			q = skipchar_utf8(p,1);
			for ( ; *p && p < q; pTarget++, p++ )
			{
				*pTarget = *p;
				qtt--;
			}			
		}
	}
	
	// new string end
	*pTarget = 0;
	
	// return string with upper case characters
	return str;
}

// ----------------------------------------------------------------------------
// Convert a string to utf-8 upper case for a specific table
unsigned char *	uppercase_utf8_table
(
	STRUCT_ISISUCTAB_UTF8	uctab_utf8[],	// utf-8 upper case table
	unsigned char *			str				// string to be converted to upper case
)
{
	// convert all string (endded by chracter '\0')
	return uppercase_utf8_length(uctab_utf8,str,UINT_MAX);
}

// ----------------------------------------------------------------------------
// Convert a string to utf-8 upper case
unsigned char *	uppercase_utf8
(
	unsigned char * str				// string to be converted to upper case
)
{
	// convert all string (endded by chracter '\0')
	return uppercase_utf8_length(isisuctab_utf8,str,UINT_MAX);
}

// ----------------------------------------------------------------------------
// Print the string character code
void mostraCodigos
(
	unsigned char * p,
	int				len
)
{
	if ( !p )
	{
		printf("mostraCodigos,p=<null>");	
		return;
	}
	
	for ( ; *p && len; p++,len-- )
	{
		printf("[%03d]",*p);
	}
	
	return;
}

// ----------------------------------------------------------------------------
// Indicate if the character is present in the utf-8 isis alphabetic table
STRUCT_ISISACTAB_UTF8 *	alphabetic_utf8
(
	unsigned char * pCharacter			// pointer to the character
)
{
	int				line;				// table line
	int				column;				// line column
	unsigned char * q;					// pointer to each character byte

	// all utf-8 isis alphabetic table lines
	for ( line = 0; isisactab_utf8[line].code[0]; line++ )
	{
		// all columns
		for ( column = 0, q = pCharacter; isisactab_utf8[line].code[column] && *q; column++, q++ )
		{
			// the table is in ascending order, greater value means not found
			if ( *q < isisactab_utf8[line].code[column] )
			{
				// return not found
				return 0;
			}

			// found?
			if ( *q == isisactab_utf8[line].code[column] )
			{
				// if it is the last column, indicates found
				if ( isisactab_utf8[line].code[column + 1] == 0 )
				{
					// return found
					return &isisactab_utf8[line];
				}

				// next column
				continue;
			}

			// next line
			break;
		}
	}
	
	// return not found
	return 0;
}

// ----------------------------------------------------------------------------
// Get next word from a string
unsigned char *	word_utf8
(
	unsigned char * key,					// key string
	unsigned char * word					// area to store the word
)
{
	unsigned char * 		p;				// pointer to the string bytes
	unsigned char * 		pTarget;		// target word pointer
	unsigned char *			copy;			// pointer to copy character to target word
	STRUCT_ISISACTAB_UTF8 *	actab_line;		// pointer to the line of the character found on the alphabetic table
	
	// all string
	for ( p = key, pTarget = word; *p; )
	{
		// find the character in the utf-8 alphabetic table
		actab_line = alphabetic_utf8(p);

		if ( actab_line )	// found
		{
			// copy to target word
			copy = actab_line->code;
			while ( *copy )
			{
				*pTarget++ = *copy++;
				p++;
			}
		}
		else	// not found
		{
			// end of word
			break;
		}
	}
	
	// assign target word end of string
	*pTarget = 0;
	
	// return next character after the word found
	return p;
}

// ----------------------------------------------------------------------------
// UTF-8 file header
unsigned char *	skip_header_file_utf8
(
	unsigned char *	pHeader				// pointer to the file header identification
)
{
	unsigned char *	p = pHeader;		// pointer to the header identification
	int				lHeader;			// header identification length
	
	// Check the byte order mark (BOM) presence
	// A BOM consists of the character code U+FEFF at the beginning of a data stream, 
	// where it can be used as a signature defining the byte order and encoding form, 
	// primarily of unmarked plaintext files
	
	lHeader = strlen(file_header_utf8);
	if ( strncmp(p,file_header_utf8,lHeader) == 0 )
	{
		// it is an utf-8 file, return pointer to the next byte after header identification
		return p + lHeader;
	}
	
	// it is not an utf-8 file, return original header pointer
	return pHeader;
}

// ----------------------------------------------------------------------------
// Get number from line string
unsigned char *	get_decimal_number
(
	unsigned char *	p,					// line position pointer
	int	*			number				// place to store found number
)
{
	unsigned char	number_buffer[4];	// string buffer to store number digits
    int 			i;					// count

	// skip non numeric
	while ( *p && !isdigit(*p) ) p++;
			
	// get decimal number
	memset(&number_buffer,0,4);
	for ( i = 0; i < 3 && *p && isdigit(*p); i++, p++ ) 
	{
		number_buffer[i] = *p;
	}

	// convert to integer
	*number = atoi(number_buffer);
	
	// validation
	if ( isdigit(*p) )	fatal("loaductb_utf8/number gt 3 chars");
	
	// return next position in the line string
	return p;
}

// ----------------------------------------------------------------------------
// Load the utf-8 upper case table
STRUCT_ISISUCTAB_UTF8 *	loaductb_utf8
(
	char *	gidbnp,											// data base name
	char *	ucfilp											// table file name
)
{
	static STRUCT_ISISUCTAB_UTF8 *	uctab_utf8;				// pointer to the loaded table
    int								pos;					// table position
    char							line		[BUFSIZ];	// line buffer
    unsigned char *					p;						// pointer to the character in the line buffer
    FILE *							fp;						// file pointer
    int								column;					// character code column
    int								line_qtt;				// quantity of lines
    int								number;					// decimal number
    int 							i;						// count

	// get the corresponding cipar file name
    ucfilp = dbxcipar(gidbnp,ucfilp,'=');
	
	// open file
    fp = fopen(ucfilp,"r");
    if ( !fp ) fatal(ucfilp);		// couldn´t open the file
    
    // count number of lines
	for ( line_qtt = 0; fgets(line,sizeof(line),fp); )
	{
		if ( line[0] == '#' )			continue;	// skip comments
		if ( strchr(line,'=') == 0 )	continue;	// ignore line without assignment
		line_qtt++;									// count line
	}
	line_qtt++;										// consider end of table area

	// alloc area to store the entire table
	uctab_utf8 = (STRUCT_ISISUCTAB_UTF8 *)ALLOC(sizeof(STRUCT_ISISUCTAB_UTF8) * line_qtt);
    if ( !uctab_utf8 ) fatal("loaductb_utf8/alloc");
	memset(uctab_utf8,0,sizeof(STRUCT_ISISUCTAB_UTF8) * line_qtt);	// reset all table

	// return to the first line
    if ( fseek(fp,0L,SEEK_SET) != 0 ) fatal(ucfilp);

	// all lines
    for ( pos = 0; fgets(line,sizeof(line),fp); )
	{
		if ( line[0] == '#' ) continue;				// ignore comments
		if ( pos >= line_qtt ) fatal("loaductb_utf8/max lines");	// just in case

		// start new line
		p = line;		
		
		// get lower character
		column	= 0;
		do
		{
			// get decimal number
			p = get_decimal_number(p,&number);

			// validation
			if ( column > 3 ) fatal("loaductb_utf8/max 4 columns");			
			
			// store decimal number that represents the character
			uctab_utf8[pos].lower[column] = number;
			
			// next column
			column++;
		} while ( *p && strchr("=\n\r",*p) == 0 );

		// check assignment
		if ( *p != '=' ) continue;
		
		// check if it is a valid number
		if ( uctab_utf8[pos].lower[0] == 0 ) continue;
		
		// check if the table is ordered
		if ( pos > 0 )
		{
			if ( strcmp(uctab_utf8[pos].lower,uctab_utf8[pos - 1].lower) < 0 )
				fatal("loaductb_utf8/it is not in ascending order");
		}

		// get upper character
		column = 0;
		do
		{
			// get decimal number
			p = get_decimal_number(p,&number);

			// validation
			if ( column > 3 ) fatal("loaductb_utf8/max 4 columns");

			// store decimal number that represents the character
			uctab_utf8[pos].upper[column] = number;

			// validation
			if ( uctab_utf8[pos].upper[column] > 0 && uctab_utf8[pos].lower[column] == 0 ) fatal("loaductb_utf8/right columns exceeds left columns");

			// next column
			column++;
		} while ( *p && strchr("#\n\r",*p) == 0 );

		// next entry
		pos++;
    }
    // close file
    fclose(fp);

	// return new allocated table
    return uctab_utf8;
}

// ----------------------------------------------------------------------------
// Load the utf-8 alphabetic table
STRUCT_ISISACTAB_UTF8 *loadactb_utf8
(
	char *	gidbnp,									// data base name
	char *	acfilp									// table file name
)
{
	static STRUCT_ISISACTAB_UTF8 * actab_utf8;		// pointer to the loaded table
    int								pos;			// table position
    char							line[BUFSIZ];	// line buffer
    unsigned char *					p;				// pointer to the character in the line buffer
    FILE *							fp;				// file pointer
    int								column;			// character code column
    int								line_qtt;		// quantity of lines
    int								number;			// decimal number
    int 							i;				// count

	// get the corresponding cipar file name
    acfilp = dbxcipar(gidbnp,acfilp,'=');
	
	// open file
    fp=fopen(acfilp,"r");
    if ( !fp ) fatal(acfilp);						// couldn´t open the file

    // count number of lines
	for ( line_qtt = 0; fgets(line,sizeof(line),fp); )
	{
		if ( line[0] == '#' )			continue;	// skip comments
		line_qtt++;									// count line
	}
	line_qtt++;

	// alloc area to store the entire table
	actab_utf8 = (STRUCT_ISISACTAB_UTF8 *)ALLOC(sizeof(STRUCT_ISISACTAB_UTF8) * line_qtt);
    if ( !actab_utf8 ) fatal("loadactb_utf8/alloc");
	memset(actab_utf8,0,sizeof(STRUCT_ISISACTAB_UTF8) * line_qtt);	// reset all table
	
	// return to the first line
    if ( fseek(fp,0L,SEEK_SET) != 0 ) fatal(acfilp);
    
	// all lines
    for ( pos = 0; fgets(line,sizeof(line),fp); )
	{
		if ( line[0] == '#' ) continue;				// ignore comments
		if ( pos >= line_qtt ) fatal("loadactb_utf8/max lines");	// just in case

		// start new line
		p = line;

		// get alphabetic character
		column = 0;
		do
		{
			// get decimal number
			p = get_decimal_number(p,&number);

			// validation
			if ( column > 3 ) fatal("loadactb_utf8/max 4 columns");
			
			// store decimal number that represents the character
			actab_utf8[pos].code[column] = number;

			// next column
			column++;
		} while ( *p && strchr("#\n\r",*p) == 0 );

		// check if it is a valid number
		if ( actab_utf8[pos].code[0] == 0 ) continue;

		// check if the table is ordered
		if ( pos > 0 )
		{
			if ( strcmp(actab_utf8[pos].code,actab_utf8[pos - 1].code) < 0 )
				fatal("loadactb_utf8/it is not in ascending order");
		}

		// next entry
		pos++;
    }
    // close file
    fclose(fp);

	// return new allocated table
    return actab_utf8;
}

#endif // UTF8
