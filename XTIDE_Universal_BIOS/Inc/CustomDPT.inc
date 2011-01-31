; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for DPT structs containing custom
;					Disk Parameter Table used by this BIOS.
%ifndef CUSTOMDPT_INC
%define CUSTOMDPT_INC


; Base Disk Parameter Table for all hard disk drives.
; DPT might have extensions for specific functions.
struc DPT
	; General Disk Parameter Table related
	.bSize		resb	1	; Size of DPT (with extensions) in bytes
	.wDrvNumAndFlags:
	.bDrvNum	resb	1	; Drive number
	.bFlags		resb	1	; DPT and Drive related flags
	.bReset		resb	1	; Drive reset status (for debugging)
	.bIdeOff	resb	1	; Offset to IDEVARS for this drive

	; Lookup values for L-CHS to P-CHS and L-CHS to LBA28 conversions
	.bShLtoP	resb	1	; Bit shift count for L-CHS to P-CHS conversion
	.wLHeads	resb	2	; Number of L-CHS Heads (1...256)

	; IDE related
	.wPCyls		resb	2	; Number of P-CHS (IDE) Cylinders (1...16383)
	.wHeadsAndSectors:
	.bPHeads	resb	1	; Number of P-CHS (IDE) Heads (1...16)
	.bPSect		resb	1	; Number of P-CHS (IDE) Sectors per Track (1...63)
	.bDrvSel	resb	1	; Drive Selection byte for Device/Head Register
	.bDrvCtrl	resb	1	; Drive Control byte for Device Control Register

	; Related to Block Mode transfers.
	; Block size is specified in sectors (1, 2, 4, 8, 16, 32, 64 or 128).
	.wSetAndMaxBlock:
	.bSetBlock	resb	1	; Currect block size (at least 1)
	.bMaxBlock	resb	1	; Maximum block size, 0 = block mode not supported
endstruc

; Bit definitions for DPT.bFlags
MASK_DPT_ADDR		EQU		110b	; Bits 1..2, Addressing Mode
FLG_DPT_EBIOS		EQU		(1<<0)	; EBIOS functions supported for this drive
FLG_DPT_FIRSTPART	EQU		(1<<3)	; First BIOS Partition of the drive (drive reset allowed)
FLG_DPT_PARTITION	EQU		(1<<4)	; BIOS Partition
FLG_DPT_USERCHS		EQU		(1<<5)	; User has specified P-CHS parameters

; Values for different addressing modes (MASK_DPT_ADDR for DPT.bFlags)
ADDR_DPT_LCHS		EQU		0		; L-CHS Addressing Mode (NORMAL in many other BIOSes)
ADDR_DPT_PCHS		EQU		1		; P-CHS Addressing Mode (LARGE in many other BIOSes)
ADDR_DPT_LBA28		EQU		2		; 28-bit LBA Addressing Mode
ADDR_DPT_LBA48		EQU		3		; 48-bit LBA Addressing Mode

; Bit definitions for DPT.bReset (inverted)
FLG_RESET_nDRDY			EQU		(1<<0)	; Drive ready to accept commands
FLG_RESET_nINITPRMS		EQU		(1<<1)	; Initialize Device Parameters successfull
FLG_RESET_nRECALIBRATE	EQU		(1<<2)	; Recalibrate successfull
FLG_RESET_nSETBLOCK		EQU		(1<<3)	; Initialize Block Mode successfull
MASK_RESET_ALL			EQU		(FLG_RESET_nDRDY | FLG_RESET_nINITPRMS | FLG_RESET_nRECALIBRATE | FLG_RESET_nSETBLOCK)


; Extended DPT for XTIDE Universal BIOS partitioned drive.
; This struct cannot exist with EDPT (EBIOS support).
struc PART_DPT
	.dpt		resb	DPT_size
	.dwStartLBA:
	.twStartLBA	resb	6	; Starting 28- or 48-bit LBA for BIOS partition
endstruc


; Extended DPT for EBIOS support.
; This struct cannot exist with PDPT (XTIDE Universal BIOS partitioned drive).
struc EBDPT
	.dpt		resb	DPT_size
	.dwCapacity:
	.twCapacity	resb	6	; Total drive capacity in sectors
endstruc


%endif ; CUSTOMDPT_INC
