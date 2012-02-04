//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        Win32Serial.h - Microsoft Windows serial code
//

#include <stdio.h>
#include "windows.h"
#include "../library/library.h"

#define PIPENAME "\\\\.\\pipe\\xtide"

class SerialAccess 
{
public:
	void Connect( char *name, struct baudRate *p_baudRate )
	{
		char buff1[20], buff2[1024];

		baudRate = p_baudRate;

		pipe = NULL;
	
		if( !name )
		{
			for( int t = 1; t <= 30 && !name; t++ )
			{
				sprintf( buff1, "COM%d", t );
				if( QueryDosDeviceA( buff1, buff2, sizeof(buff2) ) )
					name = buff1;
			}
			if( !name )
				log( -1, "No physical COM ports found" );
		}

		if( !strcmp( name, "PIPE" ) )
		{
			log( 0, "Opening named pipe %s (simulating %s baud)", PIPENAME, baudRate->display );
		
			pipe = CreateNamedPipeA( PIPENAME, PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE|PIPE_REJECT_REMOTE_CLIENTS, 2, 1024, 1024, 0, NULL );
			if( pipe == INVALID_HANDLE_VALUE )
				log( -1, "Could not CreateNamedPipe " PIPENAME );
		
			if( !ConnectNamedPipe( pipe, NULL ) )
				log( -1, "Could not ConnectNamedPipe" );

			if( baudRate->divisor > 3 )
				log( -1, "Cannot simulate baud rates with hardware multipliers" );

			speedEmulation = 1;
			resetConnection = 1;
		}
		else
		{
			if( QueryDosDeviceA( name, buff2, sizeof(buff2) ) )
			{
				COMMTIMEOUTS timeouts;
				DCB dcb;

				log( 0, "Opening %s (%lu baud)", name, baudRate->rate );
			
				pipe = CreateFileA( name, GENERIC_READ|GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0 );
				if( pipe == INVALID_HANDLE_VALUE )
					log( -1, "Could not Open \"%s\"", name );
			
				FillMemory(&dcb, sizeof(dcb), 0);
				FillMemory(&timeouts, sizeof(timeouts), 0);

				dcb.DCBlength = sizeof(dcb);
				dcb.BaudRate = baudRate->rate;
				dcb.ByteSize = 8;
				dcb.StopBits = ONESTOPBIT;
				dcb.Parity = NOPARITY;
				if( !SetCommState( pipe, &dcb ) )
					log( -1, "Could not SetCommState" );

				if( !SetCommTimeouts( pipe, &timeouts ) )
					log( -1, "Could not SetCommTimeouts" );
			}
			else
			{
				char logbuff[ 1024 ];
				int found = 0;

				sprintf( logbuff, "serial port '%s' not found, detected COM ports:", name );

				for( int t = 1; t <= 40; t++ )
				{
					sprintf( buff1, "COM%d", t );
					if( QueryDosDeviceA( buff1, buff2, sizeof(buff2) ) )
					{
						strcat( logbuff, "\n    " );
						strcat( logbuff, buff1 );
						found = 1;
					}
				}
				if( !found )
					strcat( logbuff, "\n    (none)" );
				
				log( -1, logbuff );
			}
		}
	}

	void Disconnect()
	{
		if( pipe )
		{
			CloseHandle( pipe );
			pipe = NULL;
		}
	}

	unsigned long readCharacters( void *buff, unsigned long len )
	{
		unsigned long readLen;
		int ret;

		ret = ReadFile( pipe, buff, len, &readLen, NULL );

		if( !ret || readLen == 0 )
		{
			if( GetLastError() == ERROR_BROKEN_PIPE )
				return( 0 );
		    else
				log( -1, "read serial failed (error code %d)", GetLastError() );
		}

		return( readLen );
	}

	int writeCharacters( void *buff, unsigned long len )
	{
		unsigned long writeLen;
		int ret;

		ret = WriteFile( pipe, buff, len, &writeLen, NULL );

		if( !ret || len != writeLen )
		{
			if( GetLastError() == ERROR_BROKEN_PIPE )
				return( 0 );
			else
				log( -1, "write serial failed (error code %d)", GetLastError() );
		}

		return( 1 );
	}

	SerialAccess()
	{
		pipe = NULL;
		speedEmulation = 0;
		resetConnection = 0;
		baudRate = NULL;
	}

	~SerialAccess()
	{
		Disconnect();
	}

	int speedEmulation;
	int resetConnection;

	struct baudRate *baudRate;

private:
	HANDLE pipe;
};

