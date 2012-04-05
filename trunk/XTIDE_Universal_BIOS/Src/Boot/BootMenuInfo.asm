; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for generating and accessing drive
;					information to be displayed on boot menu.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html				
;
				
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Creates new BOOTMENUINFO struct for detected hard disk.
;
; BootMenuInfo_CreateForHardDisk
;	Parameters:
;		DL:		Drive number
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		ES:BX:	Ptr to BOOTMENUINFO (if successful)
;	Corrupts registers:
;		AX, BX, CX, DX, DI
;--------------------------------------------------------------------
BootMenuInfo_CreateForHardDisk:
	call	BootMenuInfo_ConvertDPTtoBX			; ES:BX now points to new BOOTMENUINFO

	; Store Drive Name
	push	ds									; Preserve RAMVARS
	push	si

	push	es									; ES copied to DS
	pop		ds

	add		si, BYTE ATA1.strModel				; DS:SI now points drive name
	lea		di, [bx+BOOTMENUINFO.szDrvName]		; ES:DI now points to name destination
	mov		cx, MAX_HARD_DISK_NAME_LENGTH / 2	; Max number of WORDs allowed
.CopyNextWord:
	lodsw
	xchg	al, ah								; Change endianness
	stosw
	loop	.CopyNextWord
	xor		ax, ax								; Zero AX and clear CF
	stosw										; Terminate with NULL

	pop		si
	pop		ds
		
	ret


;--------------------------------------------------------------------
; BootMenuInfo_GetTotalSectorCount
;	Parameters:
;		DS:DI:		DPT Pointer
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
BootMenuInfo_GetTotalSectorCount:
	test	BYTE [di+DPT.bFlagsLow], FLG_DRVNHEAD_LBA
	jnz		SHORT .ReturnFullCapacity
	jmp		AH15h_GetSectorCountToBXDXAX
.ReturnFullCapacity:
	jmp		AccessDPT_GetLbaSectorCountToBXDXAX


;--------------------------------------------------------------------
; Returns offset to BOOTMENUINFO based on DPT pointer.
;
; BootMenuInfo_ConvertDPTtoBX
;	Parameters:
;		DS:DI:	DPT Pointer
;	Returns:
;		BX:		Offset to BOOTMENUINFO struct
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
BootMenuInfo_ConvertDPTtoBX:
	mov		ax, di
	sub		ax, BYTE RAMVARS_size					; subtract off base of DPTs
	mov		bl, DPT_BOOTMENUINFO_SIZE_MULTIPLIER	; BOOTMENUINFO's are a whole number multiple of DPT size
	mul		bl								
	add		ax, BOOTVARS.rgBootNfo					; add base of BOOTMENUINFO
	xchg	ax, bx
	ret	
