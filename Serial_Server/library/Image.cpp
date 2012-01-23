//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        image.cpp - Abstract base class for disk image support
//

#include "library.h"
#include <memory.h>
#include <stdlib.h>
#include <string.h>

Image::Image( char *name, int p_readOnly, int p_drive )
{
}

Image::Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_lba )
{
}

Image::Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_cyl, unsigned long p_head, unsigned long p_sect, int p_useCHS )
{
}

void Image::init( char *name, int p_readOnly, int p_drive, unsigned long p_cyl, unsigned long p_head, unsigned long p_sect, int p_useCHS )
{
	double sizef;

	for( char *c = shortFileName = name; *c; c++ )
		if( *c == '\\' || *c == '/' || *c == ':' )
			shortFileName = c+1;

	if( *(shortFileName) == 0 )
	{
		log( 1, "Can't parse '%s' for short file name\n\n", name );
		shortFileName = "SerDrive";
	}
  
	readOnly = p_readOnly;
	drive = p_drive;

	if( totallba > 0xfffffff )     // lba28 limit - 28 bits
		log( -1, "'%s', Image size larger than LBA28 maximum of 137,438,952,960 bytes, %lu", name, totallba );

	if( totallba == 0 )
		log( -1, "'%s', Image size zero?" );

	if( p_useCHS )
	{
		if( p_cyl )
		{
			if( p_sect > 63 || (p_head > 16 || p_head < 1) || (p_cyl > 1024 || p_cyl < 1) )
				log( -1, "'%s', parts of the CHS geometry (%lu:%lu:%lu) are out of the range (1-1024:1-16:1-63)", name, p_cyl, p_head, p_sect );
			else if( totallba != (p_sect * p_head * p_cyl) )
				log( -1, "'%s', file size does not match geometry", name );
			sect = p_sect;
			head = p_head;
			cyl = p_cyl;
		}
		else
		{
			if( (totallba % 16) != 0 || ((totallba/16) % 63) != 0 )
				log( -1, "'%s', file size does not match standard CHS geometry (x:16:63), please specify geometry explicitly with -g", name );
			else
			{
				sect = 63;
				head = 16;
				cyl = (totallba / sect / head);
				if( cyl > 1024 )
					log( -1, "'%s', CHS geometry of %lu:%lu:%lu is larger than maximum values 1024:16:63", name, cyl, head, sect );
			}
		}
	}
	else
	{
		sect = 0;
		head = 0;
		cyl = 0;
	}
	useCHS = p_useCHS;

	sizef = totallba/2048.0;
	if( useCHS )
		log( 0, "Opening '%s', CHS geometry %u:%u:%u, total size %.1lf MB", name, cyl, sect, head, sizef );
	else
		log( 0, "Opening '%s', total lba %lu, total size %.1lf MB", name, totallba, sizef );
}

int Image::parseGeometry( char *str, unsigned long *p_cyl, unsigned long *p_head, unsigned long *p_sect )
{
	char *c, *s, *h;
	unsigned long cyl, sect, head;

	c = str;
	for( h = c; *h && *h != ':' && *h != 'x' && *h != 'X'; h++ ) ;
	if( !*h )
		return( 0 );

	*h = '\0';
	h++;
	for( s = h+1; *s && *s != ':' && *s != 'x' && *s != 'X'; s++ ) ; 
	if( !*s )
		return( 0 );

	*s = '\0';
	s++;

	cyl = atol(c);
	head = atol(h);
	sect = atol(s);

	if( cyl == 0 || sect == 0 || head == 0 )
		return( 0 );

	*p_cyl = cyl;
	*p_head = head;
	*p_sect = sect;

	return( 1 );
}

#define ATA_wGenCfg 0
#define ATA_wCylCnt 1
#define ATA_wHeadCnt 3
#define ATA_wBpTrck 4
#define ATA_wBpSect 5
#define ATA_wSPT 6
#define ATA_strSerial 10
#define ATA_strFirmware 23
#define ATA_strModel 27
#define ATA_wCaps 49
#define ATA_wCurCyls 54
#define ATA_wCurHeads 55
#define ATA_wCurSPT 56
#define ATA_dwCurSCnt 57
#define ATA_dwLBACnt 60

#define ATA_VendorSpecific_ReturnPortBaud 158

#define ATA_wCaps_LBA 0x200

#define ATA_wGenCfg_FIXED 0x40

struct comPorts {
	unsigned long port;
	unsigned char com;
};
struct comPorts supportedComPorts[] = 
{ 
  { 0x3f8, '1' }, 
  { 0x2f8, '2' }, 
  { 0x3e8, '3' }, 
  { 0x2e8, '4' }, 
  { 0x2f0, '5' }, 
  { 0x3e0, '6' }, 
  { 0x2e0, '7' }, 
  { 0x260, '8' },
  { 0x368, '9' },
  { 0x268, 'A' },
  { 0x360, 'B' },
  { 0x270, 'C' },
  { 0, 0 } 
};

void Image::respondInquire( unsigned short *buff, struct baudRate *baudRate, unsigned char portAndBaud )
{
	unsigned short comPort = 0;
	struct comPorts *cp;

	if( portAndBaud )
	{
		for( cp = supportedComPorts; cp->port && cp->port != ((portAndBaud << 3) + 0x260); cp++ ) ;
		if( cp->port )
			comPort = cp->com;
	}
	  
	memset( &buff[0], 0, 514 );

	if( comPort )
		sprintf( (char *) &buff[ATA_strModel], "%.20s (COM%d/%s)", shortFileName, comPort, baudRate->display );
	else
		sprintf( (char *) &buff[ATA_strModel], "%.30s (%s baud)", shortFileName, baudRate->display );

	// strncpy( (char *) &buff[ATA_strModel], img->shortFileName, 40 );

	strncpy( (char *) &buff[ATA_strSerial], "serial", 20 );
	strncpy( (char *) &buff[ATA_strFirmware], "firmw", 8 );

	for( int t = ATA_strModel; t < ATA_strModel+40; t++ )
		buff[t] = (buff[t] >> 8) | (buff[t] << 8);

	if( useCHS )
	{
		buff[ ATA_wCylCnt ] = cyl;
		buff[ ATA_wHeadCnt ] = head;
		buff[ ATA_wSPT ] = sect;
	}
	else
	{
		buff[ ATA_wCaps ] = ATA_wCaps_LBA;
		buff[ ATA_dwLBACnt ] = (unsigned short) (totallba & 0xffff);
		buff[ ATA_dwLBACnt+1 ] = (unsigned short) (totallba >> 16);
	}

	buff[ ATA_wGenCfg ] = ATA_wGenCfg_FIXED;
	//					buff[ ATA_VendorSpecific_ReturnPortBaud ] = retWord;
}
