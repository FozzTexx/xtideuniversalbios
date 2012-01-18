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
#include "Win32Serial.h"

void usage(void)
{
	char *usageStrings[] = {
		"SerDrive - XTIDE Universal BIOS Serial Drive Server",
		"Version 1.2.0_wip, Built " __DATE__,
		"",
		"usage: SerDrive [options] imagefile [[slave-options] slave-imagefile]",
		"",
		"  -g cyl:sect:head  Geometry in cylinders, sectors per cylinder, and heads",
		"                    (default is 65:63:16 for a 32 MB disk)",
		"",
		"  -n [megabytes]    Create new disk with given size or use -g geometry",
		"",
		"  -p                Named Pipe mode for emulators (pipe is '" PIPENAME "')",
		"",
		"  -c COMPortNumber  COM Port to use (default is first found)",
		"",
		"  -b BaudRate       Baud rate to use on the COM port ",
		"                    Without a rate multiplier: 2400, 9600, 38400, 115200",
		"                    With a 2x rate multiplier: 4800, 19200, 76800, 230400",
		"                    With a 4x rate multiplier: 9600, 38400, 153600, 460800",
		"                    Abbreviations also accepted (ie, '460K', '38.4K', etc)",
		"                    (default is 9600, 115200 in named pipe mode)",
		"",
		"  -t                Disable timeout, useful for long delays when debugging",
		"",
		"  -r                Read Only disk, do not allow writes",
		"",
		"  -v [level]        Reporting level 1-6, with increasing information",
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

	Serial *serial;
	Image *img;
	struct baudRate *baudRate;

	int timeoutEnabled = 1;

	char *ComPort = NULL, ComPortBuff[20];

	_fmode = _O_BINARY;

	unsigned long cyl = 0, sect = 0, head = 0;
	int readOnly = 0, createFile = 0, explicitGeometry = 0;

	int imagecount = 0;
	Image *images[2] = { NULL, NULL };

	baudRate = baudRateMatchString( "9600" );

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
				baudRate = baudRateMatchString( "115200" );
				break;			  
			case 'g': case 'G':
				if( !Image::parseGeometry( argv[++t], &cyl, &sect, &head ) )
					usage();
				explicitGeometry = 1;
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
					explicitGeometry = 1;
				}
				break;
			case 't': case 'T':
				timeoutEnabled = 0;
				break;
			case 'b': case 'B':
				if( !(baudRate = baudRateMatchString( argv[++t] )) )
				{
						fprintf( stderr, "Unknown Baud Rate %s\n\n", argv[t] );
						usage();
				}
				break;
			default:
				fprintf( stderr, "Unknown Option: %s\n\n", argv[t] );
				usage();
			}
		}
		else if( imagecount < 2 )
		{
			images[imagecount] = new FlatImage( argv[t], readOnly, imagecount, createFile, cyl, sect, head );
			imagecount++;
			createFile = readOnly = cyl = sect = head = 0;
		}
		else
			usage();
	}

	if( imagecount == 0 )
		usage();

	do
	{
		serial = new Win32Serial( ComPort, baudRate );

		processRequests( serial, images[0], images[1], timeoutEnabled, verbose );

		delete serial;

		if( serial->resetConnection )
			log( 0, "Connection closed, reset..." );
	}
	while( serial->resetConnection );
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
