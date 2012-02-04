//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        Win32.cpp - Microsoft Windows 32-bit application
//
// This file contains the entry point for the Win32 version of the server.
// It also handles log reporting, timers, and command line parameter parsing.
// 

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdarg.h>

#include "../library/library.h"
#include "../library/flatimage.h"

void usage(void)
{
	char *usageStrings[] = {
		"SerDrive - XTIDE Universal BIOS Serial Drive Server",
		"Version 1.2.0_wip, Built " __DATE__,
		"",
		"usage: SerDrive [options] imagefile [[slave-options] slave-imagefile]",
		"",
		"  -g [cyl:head:sect]  Geometry in cylinders, sectors per cylinder, and heads",
		"                      -g also implies CHS addressing mode (default is LBA28)",
		"",
		"  -n [megabytes]      Create new disk with given size or use -g geometry",
		"                      Maximum size is " USAGE_MAXSECTORS, 
		"                      (default is a 32 MB disk, with CHS geometry 65:63:16)",
		"",
		"  -p                  Named Pipe mode for emulators (pipe is \"" PIPENAME "\")",
		"",
		"  -c COMPortNumber    COM Port to use (default is first found)",
		"",
		"  -b BaudRate         Baud rate to use on the COM port, with client machine",
		"                      rate multiplier in effect:",
		"                          None:  2400,  4800,  9600,  28.8K,  57.6K, 115.2K",
		"                          2x:    4800,  9600, 19200,  57.6K, 115.2K, 230.4K",
		"                          4x:    9600, 19200, 38400, 115.2K, 230.4K, 460.8K",
		"                          and for completeness:               76.8K, 153.6K",
		"                      (default is 9600, 115.2K when in named pipe mode)",
		"",
		"  -t                  Disable timeout, useful for long delays when debugging",
		"",
		"  -r                  Read Only disk, do not allow writes",
		"",
		"  -v [level]          Reporting level 1-6, with increasing information",
		"",
		"On the client computer, a serial port can be configured for use as a hard disk",
		"with xtidecfg.com.  Or one can hold down the ALT key at the end of the normal",
		"IDE hard disk scan and the XTIDE Universal BIOS will scan COM1-7, at each of",
		"the four speeds given above for BaudRate.  Note that hardware rate multipliers",
		"must be taken into account on the server end, but are invisible on the client.",
		NULL };

	for( int t = 0; usageStrings[t]; t++ )
		fprintf( stderr, "%s\n", usageStrings[t] );

	exit( 1 );
}

int verbose = 0;

int main(int argc, char* argv[])
{
	DWORD len;

	unsigned long check;
	unsigned char w;

	unsigned short wbuff[256];

	SerialAccess serial;
	Image *img;
	struct baudRate *baudRate = NULL;

	int timeoutEnabled = 1;

	char *ComPort = NULL, ComPortBuff[20];

	_fmode = _O_BINARY;

	unsigned long cyl = 0, sect = 0, head = 0;
	int readOnly = 0, createFile = 0;
	int useCHS = 0;

	int imagecount = 0;
	Image *images[2] = { NULL, NULL };

	for( int t = 1; t < argc; t++ )
	{
		if( argv[t][0] == '/' || argv[t][0] == '-' )
		{
		    char *c;
			unsigned long a;
			for( c = &argv[t][1]; *c && !isdigit( *c ); c++ ) 
				;
			a = atol(c);

			switch( argv[t][1] )
			{
			case 'c': case 'C':
				a = atol( argv[++t] );
				if( a < 1 )
					usage();
				sprintf( ComPortBuff, "COM%d", a );
				ComPort = &ComPortBuff[0];
				break;
			case 'v': case 'V':
			    if( atol(argv[t+1]) != 0 )
					verbose = atol(argv[++t]);
				else
					verbose = 1;
				break;
			case 'r': case 'R':
				readOnly = 1;
				break;
			case 'p': case 'P':
				ComPort = "PIPE";
				if( !baudRate )
					baudRate = baudRateMatchString( "115200" );
				break;			  
			case 'g': case 'G':
				if( atol(argv[t+1]) != 0 )
				{
					if( !Image::parseGeometry( argv[++t], &cyl, &head, &sect ) )
						usage();
				}
				useCHS = 1;
				break;
			case 'h': case 'H': case '?':
				usage();
				break;
			case 'n': case 'N':
				createFile = 1;
				if( atol(argv[t+1]) != 0 )
				{
					unsigned long size = atol(argv[++t]);
					sect = 63;
					head = 16;
					cyl = (size*1024*2) / (16*63);
				}
				break;
			case 't': case 'T':
				timeoutEnabled = 0;
				break;
			case 'b': case 'B':
				if( !(baudRate = baudRateMatchString( argv[++t] )) || !baudRate->rate )
					log( -2, "Unknown Baud Rate \"%s\"", argv[t] );
				break;
			default:
				log( -2, "Unknown Option: \"%s\"", argv[t] );
			}
		}
		else if( imagecount < 2 )
		{
			if( createFile && cyl == 0 )
			{
				cyl = 65;
				sect = 63;
				head = 16;
			}
			images[imagecount] = new FlatImage( argv[t], readOnly, imagecount, createFile, cyl, head, sect, useCHS );
			imagecount++;
			createFile = readOnly = cyl = sect = head = useCHS = 0;
		}
		else
			usage();
	}

	if( imagecount == 0 )
		usage();

	if( !baudRate )
		baudRate = baudRateMatchString( "9600" );

	do
	{
		serial.Connect( ComPort, baudRate );

		processRequests( &serial, images[0], images[1], timeoutEnabled, verbose );

		serial.Disconnect();

		if( serial.resetConnection )
			log( 0, "Serial Connection closed, reset..." );
	}
	while( serial.resetConnection );
}

void log( int level, char *message, ... )
{
	va_list args;

	va_start( args, message );

	if( level < 0 )
	{
		fprintf( stderr, "ERROR: " );
		vfprintf( stderr, message, args );
		fprintf( stderr, "\n" );
		if( level < -1 )
		{
			fprintf( stderr, "\n" );
			usage();
		}
		exit( 1 );
	}
	else if( verbose >= level )
	{
		vprintf( message, args );
		printf( "\n" );
	}

	va_end( args );
}

unsigned long GetTime(void)
{
	return( GetTickCount() );
}

unsigned long GetTime_Timeout(void)
{
	return( 1000 );
}
