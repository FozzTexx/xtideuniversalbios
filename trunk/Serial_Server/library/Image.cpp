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
	init( name, p_readOnly, p_drive );
}

Image::Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_lba )
{
	init( name, p_readOnly, p_drive );
}

Image::Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_cyl, unsigned long p_sect, unsigned long p_head )
{
	init( name, p_readOnly, p_drive );
}

void Image::init( char *name, int p_readOnly, int p_drive )
{
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
}

int Image::parseGeometry( char *str, unsigned long *p_cyl, unsigned long *p_sect, unsigned long *p_head )
{
	char *c, *s, *h;
	unsigned long cyl, sect, head;

	c = str;
	for( s = c; *s && *s != ':' && *s != 'x' && *s != 'X'; s++ ) ;
	if( !*s )
		return( 0 );

	*s = '\0';
	s++;
	for( h = s+1; *h && *h != ':' && *h != 'x' && *h != 'X'; h++ ) ; 
	if( !*h )
		return( 0 );

	*h = '\0';
	h++;

	cyl = atol(c);
	sect = atol(s);
	head = atol(h);

	if( cyl == 0 || sect == 0 || head == 0 )
		return( 0 );

	*p_cyl = cyl;
	*p_sect = sect;
	*p_head = head;

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

#if 1
	buff[ ATA_wCylCnt ] = cyl;
	buff[ ATA_wHeadCnt ] = head;
	buff[ ATA_wSPT ] = sect;
#endif
	buff[ ATA_wGenCfg ] = ATA_wGenCfg_FIXED;
	//					buff[ ATA_VendorSpecific_ReturnPortBaud ] = retWord;
#if 0
	buff[ ATA_wCaps ] = ATA_wCaps_LBA;
  
	buff[ ATA_dwLBACnt ] = (unsigned short) (totallba & 0xffff);
	buff[ ATA_dwLBACnt+1 ] = (unsigned short) (totallba >> 16);
#endif
}
