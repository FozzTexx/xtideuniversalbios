//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        file.h - File access via standard "stdio.h" routines
//
// Routines for accessing the file system using generic routines, which
// should work on all systems.  The issue with using these is that 
// ftell() and fseek() are limited to 2 GB files (signed 32-bit quantities)
// and there is no standard for 64-bit quantities.  So, look for a 
// OS specific version of this file in the distribution, such as 
// win32/win32file.h which may be in use instead.
// 

#include <stdio.h>

class FileAccess
{
public:
	void Create( char *p_name )
	{
		fp = fopen( p_name, "r" );

		if( fp )
			log( -1, "Create Failure: '%s' already exists", p_name );
		
		if( !(fp = fopen( p_name, "w" )) )
			log( -1, "Could not create file '%s'", p_name );

		name = p_name;
	}

	void Open( char *p_name )
	{
		fp = fopen( p_name, "r+" );
		if( !fp )
			log( -1, "Could not Open '%s'", p_name );
		name = p_name;
	}

	void Close()
	{
		if( fp )
			fclose( fp );
		fp = NULL;
	}

	unsigned long SizeSectors(void)
	{
		long filesize;

		fseek( fp, 0, SEEK_END );
		filesize = ftell( fp );

		if( filesize == 0 || filesize == -1L )
			log( -1, "Could not get file size for '%s', file possibly larger than 2 GB", name );

		if( filesize & 0x1ff )
			log( -1, "'%s' not made up of 512 byte sectors", name );

		return( filesize >> 9 );     // 512 bytes per sector
	}

	void SeekSectors( unsigned long lba )
	{
		if( fseek( fp, lba * 512, SEEK_SET ) )
			log( -1, "'%s', Failed to seek to lba=%lu", name, lba );
	}

	void Read( void *buff, unsigned long len )
	{
		if( fread( buff, 1, 512, fp ) != 512 )
			log( -1, "'%s', Failed to read sector", name );
	}

	void Write( void *buff, unsigned long len )
	{
		if( fwrite( buff, 1, 512, fp ) != 512 )
			log( -1, "'%s', Failed to write sector", name );
	}

	FileAccess()
	{
		fp = NULL;
		name = NULL;
	}

	const static unsigned long MaxSectors = 4194303;  // limited by signed 32-bit file sizes 
#define USAGE_MAXSECTORS "2048 MB (signed 32-bit file size limit)"

private:
	FILE *fp;
	char *name;
};

