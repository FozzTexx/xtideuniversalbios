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

FlatImage::FlatImage( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_cyl, unsigned long p_sect, unsigned long p_head )   :   Image( name, p_readOnly, p_drive, p_create, p_cyl, p_sect, p_head )
{
	double sizef;

	if( p_create )
	{
		char buff[512];
		unsigned long size;
		unsigned long size2;
		double sizef;

		fp = fopen( name, "r" );
		if( fp )
			log( 0, "Create Failure: '%s' already exists", name );
		
		if( !(fp = fopen( name, "w" )) )
			log( 0, "Could not create file '%s'", name );

		memset( &buff[0], 0, 512 );
		size2 = size = (unsigned long) p_cyl * (unsigned long) p_sect * (unsigned long) p_head;
		while( size-- )
		{
			if( fwrite( &buff[0], 1, 512, fp ) != 512 )
				log( 0, "Create write black sector error" );
		}
		fclose( fp );
		
		sizef = size2/2048.0;
		log( 1, "Created file '%s' with geometry %u:%u:%u, size %.1lf megabytes\n", name, p_cyl, p_sect, p_head, sizef );
	}

	fp = fopen( name, "r+" );
	if( !fp )
		log( 0, "Could not Open %s", name );

	log( 1, "Opening disk image '%s'", name );

	fseek( fp, 0, SEEK_END );
	totallba = ftell( fp );

	if( !totallba )
		log( 0, "Could not get file size" );

	if( totallba & 0x1ff )
		log( 0, "File not made up of 512 byte sectors" );

	totallba >>= 9;
	if( totallba != (p_sect * p_head * p_cyl) )
	{
		if( p_sect || p_head || p_cyl )
			log( 0, "File size does not match geometry" );
		else if( (totallba % 16) != 0 || ((totallba/16) % 63) != 0 )
			log( 0, "File size does not match standard geometry (x:16:63), please give explicitly with -g" );
		else
		{
			sect = 63;
			head = 16;
			cyl = (totallba / sect / head);
		}
	}
	else
	{
		sect = p_sect;
		head = p_head;
		cyl = p_cyl;
	}

	sizef = totallba/2048.0;
	log( 1, "Using geometry %u:%u:%u, total size %.1lf megabytes", cyl, sect, head, sizef );
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


