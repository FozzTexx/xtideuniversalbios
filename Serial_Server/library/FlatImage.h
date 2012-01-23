//======================================================================
//
// Project:     XTIDE Universal BIOS, Serial Port Server
//
// File:        FlatImage.h - Header file for basic flat disk image support
//

#include <stdio.h>
#include "library.h"

class FlatImage : public Image
{
private:
	FILE *fp;

public:
	FlatImage( char *name, int p_readOnly, int p_drive, int create, unsigned long cyl, unsigned long head, unsigned long sect, int useCHS );
	~FlatImage();

	int seekSector( unsigned long cyl, unsigned long sect, unsigned long head );
	int seekSector( unsigned long lba );
	int writeSector( void *buff );
	int readSector( void *buff );
};

