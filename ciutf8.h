/* ----------------------------- ciutf8.h ---------------------------------- */
#if UTF8
	// DEFINES


	// STRUCTURES
	typedef struct struct_isisuctab_utf8
	{
		unsigned char lower	[5];	// 4 bytes and the string terminator
		unsigned char upper	[5];	// 4 bytes and the string terminator
	} STRUCT_ISISUCTAB_UTF8;
	
	typedef struct struct_isisactab_utf8
	{
		unsigned char code	[5];	// 4 bytes and the string terminator
	} STRUCT_ISISACTAB_UTF8;

	
	// EXTERNS
	extern STRUCT_ISISUCTAB_UTF8 *	isisuctab_utf8;
	extern STRUCT_ISISACTAB_UTF8 *	isisactab_utf8;
	extern unsigned char *			file_header_utf8;
	
	
	// FUNCTIONS
	size_t					strlen_utf8				(unsigned char * str);
	unsigned char *			skipchar_utf8			(unsigned char * str,size_t qtt);
	unsigned char *			previous_char_utf8		(size_t	pos,unsigned char *	str);
	unsigned char *			uppercase_utf8_length	(STRUCT_ISISUCTAB_UTF8 uctab_utf8[],unsigned char *	str,size_t qtt);
	unsigned char *			uppercase_utf8_table	(STRUCT_ISISUCTAB_UTF8 uctab_utf8[],unsigned char *	str);
	unsigned char *			uppercase_utf8			(unsigned char * str);
	void					mostraCodigos			(unsigned char * p,int len);
	STRUCT_ISISACTAB_UTF8 *	alphabetic_utf8			(unsigned char * pCharacter);
	unsigned char *			word_utf8				(unsigned char * key,unsigned char * word);
	unsigned char *			skip_header_file_utf8	(unsigned char * pHeader);
	unsigned char *			get_decimal_number		(unsigned char * p,int * number);
	STRUCT_ISISUCTAB_UTF8 *	loaductb_utf8			(char *gidbnp,char *ucfilp);
	STRUCT_ISISACTAB_UTF8 *	loadactb_utf8			(char *gidbnp,char *acfilp);
#endif // UTF8
