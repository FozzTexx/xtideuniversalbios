//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        FlatImage.cpp - Basic flat disk image file support
//

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#include "FlatImage.h"

FlatImage::FlatImage( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_cyl, unsigned long p_head, unsigned long p_sect, int p_useCHS )   :   Image( name, p_readOnly, p_drive, p_create, p_cyl, p_head, p_sect, p_useCHS )
{
	long filesize;

	if( p_create )
	{
		char buff[512];
		unsigned long size;
		unsigned long size2;
		double sizef;

		fp = fopen( name, "r" );
		if( fp )
			log( -1, "Create Failure: '%s' already exists", name );
		
		if( !(fp = fopen( name, "w" )) )
			log( -1, "Could not create file '%s'", name );

		memset( &buff[0], 0, 512 );
		size2 = size = (unsigned long) p_cyl * (unsigned long) p_sect * (unsigned long) p_head;
		while( size-- )
		{
			if( fwrite( &buff[0], 1, 512, fp ) != 512 )
				log( -1, "Create write black sector error" );
		}
		fclose( fp );
		
		sizef = size2/2048.0;
		if( p_cyl > 1024 )
			log( 0, "Created file '%s', size %.1lf MB", name, sizef );
		else
			log( 0, "Created file '%s', geometry %u:%u:%u, size %.1lf MB", name, p_cyl, p_sect, p_head, sizef );
	}

	fp = fopen( name, "r+" );
	if( !fp )
		log( -1, "Could not Open '%s'", name );

	fseek( fp, 0, SEEK_END );
	filesize = ftell( fp );

	if( filesize == 0 || filesize == -1L )
		log( -1, "Could not get file size for '%s', file possibly larger than 2 GB", name );

	if( filesize & 0x1ff )
		log( -1, "'%s' not made up of 512 byte sectors", name );

	totallba = filesize >> 9;     // 512 bytes per sector

	init( name, p_readOnly, p_drive, p_cyl, p_head, p_sect, p_useCHS );
}

int FlatImage::seekSector( unsigned long cyl, unsigned long sect, unsigned long head )
{
	return( 0 );
}

int FlatImage::seekSector( unsigned long lba )
{
	return( fseek( fp, lba * 512, SEEK_SET ) );
}

int FlatImage::writeSector( void *buff )
{
	int r;

	r = fwrite( buff, 1, 512, fp );
	fflush( fp );
	
	return( r == 512 ? 0 : 1 );
}

int FlatImage::readSector( void *buff )
{
	return( fread( buff, 1, 512, fp ) == 512 ? 0 : 1 );
}

FlatImage::~FlatImage()
{
	if( fp )
		fclose( fp );
	fp = NULL;
}


