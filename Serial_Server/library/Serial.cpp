//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        Serial.cpp - Generic functions for dealing with serial communications
//

#include "library.h"
#include <stdlib.h>
#include <string.h>

struct baudRate supportedBaudRates[] = 
{ 
	{   2400,  0x0,   "2400",   NULL }, 
	{   4800, 0xff,   "4800",   NULL }, 
	{   9600,  0x1,   "9600",   NULL }, 
	{  19200, 0xff,  "19.2K",  "19K" }, 
	{  38400,  0x2,  "38.4K",  "38K" }, 
	{  76800,  0x2,  "76.8K",  "77K" },
	{ 115200,  0x3, "115.2K", "115K" }, 
	{ 153600,  0x3, "153.6K", "154K" },
	{ 230400, 0xff, "230.4K", "230K" }, 
	{ 460800,  0x1, "460.8K", "460K" }, 
	{      0,    0,     NULL,   NULL } 
};

struct baudRate *baudRateMatchString( char *str )
{
	struct baudRate *b;
  
	unsigned long a = atol( str );
	if( a )
	{
		for( b = supportedBaudRates; b->rate; b++ )
			if( b->rate == a )
				return( b );
	}

	for( b = supportedBaudRates; b->rate; b++ )
		if( !stricmp( str, b->display ) || (b->altSelection && !stricmp( str, b->altSelection )) )
			return( b );

	return( NULL );
}

struct baudRate *baudRateMatchDivisor( unsigned char divisor )
{
	struct baudRate *b;

	for( b = supportedBaudRates; b->rate && b->divisor != divisor; b++ ) 
		;

	return( b->rate ? b : NULL );
}


