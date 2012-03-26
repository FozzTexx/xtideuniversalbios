; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for DPT structs containing custom
;					Disk Parameter Table used by this BIOS.
%ifndef CUSTOMDPT_INC
%define CUSTOMDPT_INC

; Base DPT for all device types
struc DPT	; 10 bytes
	; General Disk Parameter Table related
	.wFlags:
	.bFlagsLow					resb	1
	.bFlagsHigh					resb	1
	.bIdevarsOffset				resb	1	; Offset to IDEVARS for this drive

	; IDE Drive related
	; .bLbaHeads and .twLbaSectors are used for LBA addressing only.
	.bLbaHeads:					resb	1	; Number of LBA assisted heads (1...255)
	.twLbaSectors				resb	2	; 48-bit sector count for LBA addressing

	; .wPchsCylinders and .bPchsSectors are used for CHS addressing only.
	.wPchsCylinders				resb	2	; Number of P-CHS Cylinders (1...16383)
	.wPchsHeadsAndSectors:
	.bPchsHeads					resb	1	; Number of P-CHS heads (1...16)
	.bPchsSectors				resb	1	; Number of P-CHS Sectors per Track (1...63)
endstruc

; Bit definitions for DPT.bFlagsLow
MASKL_DPT_CHS_SHIFT_COUNT		EQU	(7<<0)	; Bits 0...3, P-CHS to L-CHS bit shift count (0...4)
FLGL_DPT_SLAVE					EQU	FLG_DRVNHEAD_DRV	; (1<<4), Drive is slave drive
MASKL_DPT_ADDRESSING_MODE		EQU	(3<<5)	; Bits 5..6, Addressing Mode (bit 6 == FLG_DRVNHEAD_LBA)
FLGL_DPT_ENABLE_IRQ				EQU	(1<<7)

; Bit definitions for DPT.bFlagsHigh
FLGH_DPT_REVERSED_A0_AND_A3		EQU	(1<<0)	; XTIDE mod, Address lines 0 and 3 reversed
FLGH_DPT_BLOCK_MODE_SUPPORTED	EQU	(1<<1)	; Use block transfer commands (must be bit 1!)
%ifdef MODULE_SERIAL
FLGH_DPT_SERIAL_DEVICE			EQU	(1<<2)	; Serial Port Device
%endif
FLGH_DPT_INTERRUPT_IN_SERVICE	EQU	(1<<3)	; Set when waiting for IRQ

; IDE device only
FLGH_DPT_INITERROR				EQU	(1<<7)

; Serial device only
FLGH_DPT_SERIAL_FLOPPY						EQU	(1<<4)
FLGH_DPT_SERIAL_FLOPPY_TYPE_MASK			EQU	0e0h
FLGH_DPT_SERIAL_FLOPPY_TYPE_FIELD_POSITION	EQU	5

; Addressing modes for DPT.wFlags
ADDRESSING_MODE_FIELD_POSITION	EQU		5
ADDRESSING_MODE_LCHS			EQU		0	; L-CHS Addressing Mode (NORMAL in many other BIOSes)
ADDRESSING_MODE_PCHS			EQU		1	; P-CHS Addressing Mode (LARGE in many other BIOSes)
ADDRESSING_MODE_LBA28			EQU		2	; 28-bit LBA Addressing Mode
ADDRESSING_MODE_LBA48			EQU		3	; 48-bit LBA Addressing Mode


; DPT for ATA devices
struc DPT_ATA	; 10 + 2 bytes = 12 bytes
	.dpt						resb	DPT_size

	; Block size is specified in sectors (1, 2, 4, 8, 16, 32, 64 or 128)
	.wSetAndMaxBlock:
	.bSetBlock					resb	1	; Current block size (do not set to zero!)
	.bMaxBlock					resb	1	; Maximum block size, 0 = block mode not supported

%ifdef MODULE_ADVANCED_ATA	; +2 extra bytes = 14 bytes
	.bPioMode					resb	1
	.bDevice					resb	1
%endif
endstruc


%ifdef MODULE_ADVANCED_ATA
; Temporary extension for DPT_ATA. Contents will be copied to BOOTMENUINFO and
; then these variables will be overridden by next DPT.
struc DPT_ADVANCED_ATA
	.dpt_ata				resb	DPT_ATA_size
	.wIdeBasePort			resb	2	; IDE Base Port
	.wMinPioActiveTimeNs	resb	2	; Minimum PIO Active Time in ns
	.wMinPioRecoveryTimeNs	resb	2	; Minimum PIO Recovery Time in ns
	.wControllerID			resb	2	; Controller specific ID WORD
	.wControllerBasePort	resb	2	; Advanced Controller port (not IDE port)
endstruc
%endif


%ifdef MODULE_SERIAL
; DPT for Serial devices
struc DPT_SERIAL
	.dpt						resb	DPT_size

	.wSerialPortAndBaud:
	.bSerialPort				resb	1	; Serial connection I/O port address, divided by 4
	.bSerialBaud				resb 	1	; Serial connection baud rate divisor
endstruc
%endif


; This is the common size for all DPTs. All DPTs must be equal size.
LARGEST_DPT_SIZE				EQU		DPT_ATA_size


; Number of Sectors per Track is fixed to 63 for LBA assist calculation.
; 1024 cylinders, 256 heads, 63 sectors = 8.4 GB limit (but DOS does not support more than 255 heads)
MAX_LCHS_CYLINDERS				EQU		1024
LBA_ASSIST_SPT					EQU		63


;--------------------------------------------------------------------
; LIMIT_LBA_CYLINDERS_IN_DXAX_TO_LCHS_CYLINDERS
;	Parameters:
;		DX:AX:	Number of LBA cylinders
;	Returns:
;		AX:		Number of L-CHS cylinders
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro LIMIT_LBA_CYLINDERS_IN_DXAX_TO_LCHS_CYLINDERS 0
	test	dx, dx
	jnz		SHORT %%LoadMaxValueToAX
	cmp		ax, MAX_LCHS_CYLINDERS
	jbe		SHORT %%NoNeedToModify
%%LoadMaxValueToAX:
	mov		ax, MAX_LCHS_CYLINDERS
%%NoNeedToModify:
%endmacro


%endif ; CUSTOMDPT_INC
