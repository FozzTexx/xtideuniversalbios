//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        process.cpp - Processes commands received over the serial port
//

#include "library.h"
#include <memory.h>
#include <string.h>

union _buff {
	struct {
		unsigned char command;
		unsigned char driveAndHead;
		unsigned char count;
		unsigned char sector;
		unsigned short cylinder;
	} chs;
	struct {
		unsigned char command;
		unsigned char bits24;
		unsigned char count;
		unsigned char bits00;
		unsigned char bits08;
		unsigned char bits16;
	} lba;
	struct {
		unsigned char command;
		unsigned char driveAndHead;
		unsigned char count;
		unsigned char undefined1;
		unsigned char portAndBaud;
		unsigned char undefined2;
	} inquire;
	unsigned char b[514];
	unsigned short w[257];
} buff;

#define SERIAL_COMMAND_HEADER 0xa0

#define SERIAL_COMMAND_WRITE 1
#define SERIAL_COMMAND_READWRITE 2
#define SERIAL_COMMAND_RWMASK 3
#define SERIAL_COMMAND_INQUIRE 0

#define SERIAL_COMMAND_MASK 0xe3
#define SERIAL_COMMAND_HEADERMASK 0xe0

#define SERIAL_INQUIRE_PORTANDBAUD_BAUD 3
#define SERIAL_INQUIRE_PORTANDBAUD_PORT 0xfc

void processRequests( Serial *serial, Image *image0, Image *image1, int timeoutEnabled, int verboseLevel )
{
	unsigned char workCommand;
	int workOffset, workCount;

	int vtype;

	unsigned long mylba;
	unsigned long readto;
	unsigned long buffoffset;
	int timeout;
	unsigned long lasttick;
	unsigned short crc;
	unsigned long GetTime_Timeout_Local;
	unsigned long len;
	Image *img;
	unsigned long cyl, sect, head;

	GetTime_Timeout_Local = GetTime_Timeout();

	buffoffset = 0;
	readto = 0;
	timeout = 0;
	workCount = workOffset = workCommand = 0;
	lasttick = GetTime();

	while( timeout || (len = serial->readCharacters( &buff.b[buffoffset], (readto ? readto-buffoffset : 1) )) )
	{
		buffoffset += len;

		if( verboseLevel >= 4 )
		{
			char logBuff[ 514*9 + 10 ];
			int logCount;

			if( verboseLevel == 6 || buffoffset == readto )
			{
				if( verboseLevel == 4 && buffoffset > 11 )
					logCount = 11;
				else
					logCount = buffoffset;

				for( int t = 0; t < logCount; t++ )
					sprintf( &logBuff[t*9], "[%3d:%02x] ", t, buff.b[t] );
				if( logCount != buffoffset )
					sprintf( &logBuff[logCount*9], "... " );

				log( 4, logBuff );
			}
		}

		timeout = 0;

		if( buffoffset != 1 && (timeoutEnabled && GetTime() > lasttick + GetTime_Timeout_Local) )
		{
			timeout = 1;
			buff.b[0] = buff.b[buffoffset];
			buffoffset = 0;
			len = 1;
			workCount = 0;
			log( 2, "Timeout waiting on command" );
			continue;
		}

		lasttick = GetTime();

		if( buffoffset == 1 && !readto )
		{
			if( workCount )
			{
				readto = 1;
			}
			else if( (buff.b[0] & SERIAL_COMMAND_HEADERMASK) == SERIAL_COMMAND_HEADER )
			{
				readto = 8;
			}
			else
			{
				if( verboseLevel >= 2 )
				{
					if( buff.b[0] >= 0x20 && buff.b[0] <= 0x7e )
						log( 3, "[%d:%c]", buff.b[0], buff.b[0] );
					else
						log( 3, "[%d]", buff.b[0] );
				}
				buffoffset = 0;
				continue;
			}
		}

		// read 512 bytes from serial port - only one reason for that size: Write Sector
		//
		if( buffoffset == readto && readto == 514 )
		{
			buffoffset = readto = 0;
			if( (crc = checksum( &buff.w[0], 256 )) != buff.w[256] )
			{
				log( 1, "Bad Write Sector Checksum" );
				continue;
			}

			if( img->readOnly )
			{
				log( 2, "Attempt to write to read-only image" );
				continue;
			}

			img->seekSector( mylba + workOffset );
			img->writeSector( &buff.w[0] );

			if( serial->writeCharacters( &buff.w[256], 2 ) != 2 )
				log( 1, "Serial Port Write Error" );

			workOffset++;
			workCount--;
		}

		// 8 byte command received, or a continuation of the previous command
		//
		else if( (buffoffset == readto && readto == 8) ||
				 (buffoffset == readto && readto == 1 && workCount) )
		{
			buffoffset = readto = 0;
			if( workCount )
			{
				if( buff.b[0] != (workCount-0) )
				{
					log( 1, "Continue Fault: Received=%d, Expected=%d", buff.b[0], workCount );
					workCount = 0;
					continue;
				}
			}
			else
			{
				if( (crc = checksum( &buff.w[0], 3 )) != buff.w[3] )
				{
					log( 1, "Bad Command Checksum: %02x %02x %02x %02x %02x %02x %02x %02x, Checksum=%02x",
						 buff.b[0], buff.b[1], buff.b[2], buff.b[3], buff.b[4], buff.b[5], buff.b[6], buff.b[7], crc);
					continue;
				}

				if( (buff.inquire.driveAndHead & ATA_DriveAndHead_Drive) )
				{
					if( !image1 )
					{
						log( 2, "slave drive selected when not supplied" );
						continue;
					}
					img = NULL;
				}
				else
					img = image0;

				workCommand = buff.chs.command & SERIAL_COMMAND_RWMASK;

				if( (workCommand != SERIAL_COMMAND_INQUIRE) && (buff.chs.command & ATA_COMMAND_LBA) )
				{
					mylba = ((((unsigned long) buff.lba.bits24) & ATA_COMMAND_HEADMASK) << 24) 
						| (((unsigned long) buff.lba.bits16) << 16) 
						| (((unsigned long) buff.lba.bits08) << 8) 
						| ((unsigned long) buff.lba.bits00);
					vtype = 1;
				}
				else
				{
					cyl = buff.chs.cylinder;
					sect = buff.chs.sector;
					head = (buff.chs.driveAndHead & ATA_COMMAND_HEADMASK);
					mylba = (((cyl*img->head + head)*img->sect) + sect-1);
					vtype = 2;
				}

				if( (workCommand & SERIAL_COMMAND_WRITE) && img->readOnly )
				{
					log( 2, "Write attempt to Read Only disk" );
					continue;
				}

				workOffset = 0;
				workCount = buff.chs.count;
			}

			if( workCount && (workCommand == (SERIAL_COMMAND_WRITE | SERIAL_COMMAND_READWRITE)) )
			{
				readto = 514;
			}
			else 
			{
				if( workCommand == SERIAL_COMMAND_INQUIRE )
				{
					log( 2, "Inquire Disk Information, Drive=%d", 
						 (buff.inquire.driveAndHead & ATA_DriveAndHead_Drive) >> 4 );

					if( serial->speedEmulation && 
						(buff.inquire.portAndBaud & SERIAL_INQUIRE_PORTANDBAUD_BAUD) != serial->baudRate->divisor )
					{
						struct baudRate *br;

						br = baudRateMatchDivisor( buff.inquire.portAndBaud & SERIAL_INQUIRE_PORTANDBAUD_BAUD );

						if( br )
							log( 2, "    Ignoring Inquire with Baud Rate=%d", br->rate );
						else
							log( 2, "    Ignoring Inquire with Unknown Baud Rate (portAndBaud=%d)", buff.inquire.portAndBaud );
						workCount = 0;
						continue;
					}

					img->respondInquire( &buff.w[0], serial->baudRate, buff.inquire.portAndBaud );
				}
				else
				{
					img->seekSector( mylba + workOffset );
					img->readSector( &buff.w[0] );
				}

				buff.w[256] = checksum( &buff.w[0], 256 );

				if( serial->writeCharacters( &buff.w[0], 514 ) != 514 )
				{
					log( 1, "Serial Port Write Error" );
				}

				workCount--;
				workOffset++;
			}

			if( verboseLevel > 1 )
			{
				if( vtype == 1 )
					log( 2, "%s: LBA=%u, Count=%u", 
						 (workCommand & SERIAL_COMMAND_WRITE ? "Write" : "Read"),
						 mylba, workCount );
				else if( vtype == 2 )
					log( 2, "%s: Cylinder=%u, Sector=%u, Head=%u, Count=%u, LBA=%u", 
						 (workCommand & SERIAL_COMMAND_WRITE ? "Write" : (workCommand & SERIAL_COMMAND_READWRITE ? "Read" : "Inquire")),
						 cyl, sect, head, workCount, mylba );

				vtype = 0;		  

				if( workOffset > 1 )
					log( 3, "       Offset=%u, Checksum=%04x", workOffset-1, buff.w[256] );				  
			}
		}
	}
}
