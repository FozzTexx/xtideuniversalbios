//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        Win32Serial.h - Microsoft Windows serial code
//

#include "windows.h"
#include "../library/library.h"

#define PIPENAME "\\\\.\\pipe\\xtide"

class Win32Serial : public Serial
{
public:
	Win32Serial( char *name, struct baudRate *baudRate );
	~Win32Serial();

	unsigned long readCharacters( void *buff, unsigned long len );
	unsigned long writeCharacters( void *buff, unsigned long len );

private:
	HANDLE pipe;
};

