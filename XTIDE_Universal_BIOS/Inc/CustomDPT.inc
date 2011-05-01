; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for DPT structs containing custom
;					Disk Parameter Table used by this BIOS.
%ifndef CUSTOMDPT_INC
%define CUSTOMDPT_INC

; Base DPT for all device types
struc DPT	; 8 bytes
	; General Disk Parameter Table related
	.wFlags						resb	2
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


; Bit definitions for DPT.wFlags
MASK_DPT_CHS_SHIFT_COUNT		EQU	(7<<0)	; Bits 0...3, P-CHS to L-CHS bit shift count (0...4)
FLG_DPT_SLAVE					EQU	FLG_DRVNHEAD_DRV	; (1<<4), Drive is slave drive
MASK_DPT_ADDRESSING_MODE		EQU	(3<<5)	; Bits 5..6, Addressing Mode (bit 6 == FLG_DRVNHEAD_LBA)
FLG_DPT_ENABLE_IRQ				EQU	(1<<7)
FLG_DPT_REVERSED_A0_AND_A3		EQU	(1<<8)	; XTIDE mod, Address lines 0 and 3 reversed
FLG_DPT_SERIAL_DEVICE			EQU	(1<<9)	; Serial Port Device
FLG_DPT_BLOCK_MODE_SUPPORTED	EQU	(1<<10)	; Use block transfer commands
FLG_DPT_INTERRUPT_IN_SERVICE	EQU	(1<<11)	; Set when waiting for IRQ
FLG_DPT_RESET_nDRDY				EQU	(1<<12)	; Drive ready to accept commands
FLG_DPT_RESET_nINITPRMS			EQU	(1<<13)	; Initialize Device Parameters successfull
FLG_DPT_RESET_nRECALIBRATE		EQU	(1<<14)	; Recalibrate successfull
FLG_DPT_RESET_nSETBLOCK			EQU	(1<<15)	; Initialize Block Mode successfull
MASK_DPT_RESET					EQU	0F000h

; Addressing modes for DPT.wFlags
ADDRESSING_MODE_FIELD_POSITION	EQU		5
ADDRESSING_MODE_LCHS			EQU		0	; L-CHS Addressing Mode (NORMAL in many other BIOSes)
ADDRESSING_MODE_PCHS			EQU		1	; P-CHS Addressing Mode (LARGE in many other BIOSes)
ADDRESSING_MODE_LBA28			EQU		2	; 28-bit LBA Addressing Mode
ADDRESSING_MODE_LBA48			EQU		3	; 48-bit LBA Addressing Mode


%endif ; CUSTOMDPT_INC
