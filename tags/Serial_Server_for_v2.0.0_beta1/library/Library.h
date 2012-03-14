//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        library.h - Include file for users of the library
//

#ifndef LIBRARY_H_INCLUDED
#define LIBRARY_H_INCLUDED

#define SERIAL_SERVER_MAJORVERSION 1
#define SERIAL_SERVER_MINORVERSION 0

void log( int level, char *message, ... );

unsigned long GetTime(void);
unsigned long GetTime_Timeout(void);

unsigned short checksum( unsigned short *wbuff, int wlen );

struct floppyInfo {
	unsigned char real;
	unsigned long size;
	unsigned char type;
	unsigned char cylinders;
	unsigned char heads;
	unsigned char sectors;
};

struct floppyInfo *FindFloppyInfoBySize( double size );

class Image
{
public:
	virtual void seekSector( unsigned long lba ) = 0;

	virtual void writeSector( void *buff ) = 0;

	virtual void readSector( void *buff ) = 0;

	Image( char *name, int p_readOnly, int p_drive );
	Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_lba );
	Image( char *name, int p_readOnly, int p_drive, int p_create, unsigned long p_cyl, unsigned long p_head, unsigned long p_sect, int p_useCHS );

	virtual ~Image() {};

	unsigned long cyl, sect, head;
	unsigned char floppy, floppyType;
	int useCHS;

	unsigned long totallba;

	char *shortFileName;
	int readOnly;
	int drive;

	static int parseGeometry( char *str, unsigned long *p_cyl, unsigned long *p_head, unsigned long *p_sect );

	void respondInquire( unsigned short *buff, unsigned short originalPortAndBaud, struct baudRate *baudRate, unsigned short port, unsigned char scan );

	void init( char *name, int p_readOnly, int p_drive, unsigned long p_cyl, unsigned long p_head, unsigned long p_sect, int p_useCHS );
};

struct baudRate {
	unsigned long rate;
	unsigned char divisor;
	char *display;
};
struct baudRate *baudRateMatchString( char *str );
struct baudRate *baudRateMatchDivisor( unsigned char divisor );

#ifdef WIN32
#include "../win32/win32serial.h"
#else
// there is no standard way to read/write and configure the serial port, OS specific only
#endif

#ifdef WIN32
#include "../win32/win32file.h"
#else
#include "file.h"
#endif

void processRequests( SerialAccess *serial, Image *image0, Image *image1, int timeoutEnabled, int verboseLevel );

#endif
