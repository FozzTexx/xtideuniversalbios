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
	{   2400,  0x0,   "2400" },
	{   4800, 0xff,   "4800" },
	{   9600,  0x1,   "9600" },
	{  19200, 0xff,  "19.2K" },
	{  38400,  0x2,  "38.4K" },
	{  76800, 0xff,  "76.8K" },
	{ 115200,  0x3, "115.2K" },
	{ 153600, 0xff, "153.6K" },
	{ 230400, 0xff, "230.4K" },
	{ 460800, 0xff, "460.8K" },
	{      0,    0,     NULL }
};

struct baudRate *baudRateMatchString( char *str )
{
	struct baudRate *b;
  
	unsigned long a = atol( str );
	if( a )
	{
		for( b = supportedBaudRates; b->rate; b++ )
			if( b->rate == a || (b->rate / 1000) == a || ((b->rate + 500) / 1000) == a )
				return( b );
	}

	return( NULL );
}

struct baudRate *baudRateMatchDivisor( unsigned char divisor )
{
	struct baudRate *b;

	for( b = supportedBaudRates; b->rate && b->divisor != divisor; b++ ) 
		;

	return( b->rate ? b : NULL );
}


