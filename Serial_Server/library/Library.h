//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        library.h - Include file for users of the library
//

#ifndef LIBRARY_H_INCLUDED
#define LIBRARY_H_INCLUDED

#include "stdio.h"

void log( int level, char *message, ... );
unsigned long GetTime(void);
unsigned long GetTime_Timeout(void);

unsigned short checksum( unsigned short *wbuff, int wlen );

class Image
{
public:
	virtual int seekSector( unsigned long cyl, unsigned long sect, unsigned long head ) = 0;
	virtual int seekSector( unsigned long lba ) = 0;

	virtual int writeSector( void *buff ) = 0;
	
	virtual int readSector( void *buff ) = 0;

	Image( char *name, int p_readOnly, int p_drive );
	Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_lba );
	Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_cyl, unsigned long p_head, unsigned long p_sect, int p_useCHS );

	virtual ~Image() {};

	unsigned long cyl, sect, head;
	int useCHS;

	unsigned long totallba;
	
	char *shortFileName;
	int readOnly;
	int drive;

	static int parseGeometry( char *str, unsigned long *p_cyl, unsigned long *p_head, unsigned long *p_sect );

	void respondInquire( unsigned short *buff, struct baudRate *baudRate, unsigned char portAndBaud );

	void init( char *name, int p_readOnly, int p_drive, unsigned long p_cyl, unsigned long p_head, unsigned long p_sect, int p_useCHS );
};

struct baudRate {
	unsigned long rate;
	unsigned char divisor;
	char *display;
};
struct baudRate *baudRateMatchString( char *str );
struct baudRate *baudRateMatchDivisor( unsigned char divisor );

class Serial
{
public:
	virtual unsigned long readCharacters( void *buff, unsigned long len ) = 0;

	virtual unsigned long writeCharacters( void *buff, unsigned long len ) = 0;

	Serial( char *name, struct baudRate *p_baudRate ) 
	{
		speedEmulation = 0;
		resetConnection = 0;
		baudRate = p_baudRate;
	};

	virtual ~Serial() {};

	int speedEmulation;
	int resetConnection;

	struct baudRate *baudRate;
};

void processRequests( Serial *serial, Image *image0, Image *image1, int timeoutEnabled, int verboseLevel );

#define ATA_COMMAND_LBA 0x40
#define ATA_COMMAND_HEADMASK 0xf

#define ATA_DriveAndHead_Drive 0x10

#endif
