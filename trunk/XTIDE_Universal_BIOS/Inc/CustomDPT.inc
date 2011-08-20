; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for DPT structs containing custom
;					Disk Parameter Table used by this BIOS.
%ifndef CUSTOMDPT_INC
%define CUSTOMDPT_INC

; Base DPT for all device types
struc DPT	; 8 bytes
	; General Disk Parameter Table related
	.wFlags:
	.bFlagsLow					resb	1
	.bFlagsHigh					resb	1
	.bIdevarsOffset				resb	1	; Offset to IDEVARS for this drive

	; L-CHS to P-CHS and L-CHS to LBA28 conversion related
	.bLchsHeads					resb	1	; Number of L-CHS Heads (1...255)

	; IDE Drive related
	.wPchsCylinders				resb	2	; Number of P-CHS (IDE) Cylinders (1...16383)
	.wPchsHeadsAndSectors:
	.bPchsHeads					resb	1	; Number of P-CHS (IDE) Heads (1...16)
	.bPchsSectors				resb	1	; Number of P-CHS (IDE) Sectors per Track (1...63)
endstruc

; DPT for ATA devices
struc DPT_ATA	; 8 + 2 bytes = 10 bytes
	.dpt						resb	DPT_size

	; Block size is specified in sectors (1, 2, 4, 8, 16, 32 or 64).
	; 128 is not allowed to prevent offset overflow during data transfer.
	.wSetAndMaxBlock:
	.bSetBlock					resb	1	; Current block size (at least 1)
	.bMaxBlock					resb	1	; Maximum block size, 0 = block mode not supported
endstruc

LARGEST_DPT_SIZE				EQU		DPT_ATA_size


; Bit definitions for DPT.bFlagsLow
MASKL_DPT_CHS_SHIFT_COUNT		EQU	(7<<0)	; Bits 0...3, P-CHS to L-CHS bit shift count (0...4)
FLGL_DPT_SLAVE					EQU	FLG_DRVNHEAD_DRV	; (1<<4), Drive is slave drive
MASKL_DPT_ADDRESSING_MODE		EQU	(3<<5)	; Bits 5..6, Addressing Mode (bit 6 == FLG_DRVNHEAD_LBA)
FLGL_DPT_ENABLE_IRQ				EQU	(1<<7)

; Bit definitions for DPT.bFlagsHigh
FLGH_DPT_REVERSED_A0_AND_A3		EQU	(1<<0)	; XTIDE mod, Address lines 0 and 3 reversed
FLGH_DPT_BLOCK_MODE_SUPPORTED	EQU	(1<<1)	; Use block transfer commands (must be bit 1!)
FLGH_DPT_SERIAL_DEVICE			EQU	(1<<2)	; Serial Port Device
FLGH_DPT_INTERRUPT_IN_SERVICE	EQU	(1<<3)	; Set when waiting for IRQ
FLGH_DPT_RESET_nDRDY			EQU	(1<<4)	; Drive ready to accept commands
FLGH_DPT_RESET_nINITPRMS		EQU	(1<<5)	; Initialize Device Parameters successfull
FLGH_DPT_RESET_nRECALIBRATE		EQU	(1<<6)	; Recalibrate successfull
FLGH_DPT_RESET_nSETBLOCK		EQU	(1<<7)	; Initialize Block Mode successfull
MASKH_DPT_RESET					EQU	0F0h

; Addressing modes for DPT.wFlags
ADDRESSING_MODE_FIELD_POSITION	EQU		5
ADDRESSING_MODE_LCHS			EQU		0	; L-CHS Addressing Mode (NORMAL in many other BIOSes)
ADDRESSING_MODE_PCHS			EQU		1	; P-CHS Addressing Mode (LARGE in many other BIOSes)
ADDRESSING_MODE_LBA28			EQU		2	; 28-bit LBA Addressing Mode
ADDRESSING_MODE_LBA48			EQU		3	; 48-bit LBA Addressing Mode


%endif ; CUSTOMDPT_INC
