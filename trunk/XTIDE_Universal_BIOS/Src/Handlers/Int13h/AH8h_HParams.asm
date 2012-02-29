; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=8h, Read Disk Drive Parameters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=8h, Read Disk Drive Parameters.
;
; AH8h_HandlerForReadDiskDriveParameters
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;       BL:     Drive Type (for floppies only)
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...254)
;		DL:		Number of drives
;       ES:DI:  Floppy DPT (for floppies only)
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
AH8h_HandlerForReadDiskDriveParameters:
	test	di,di
	jnz		SHORT .OurDrive

	call	Int13h_CallPreviousInt13hHandler
	jnc		SHORT .MidGame
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
		
.OurDrive:		
	call	AH8h_GetDriveParameters

%ifdef MODULE_SERIAL_FLOPPY
	push	cs							; setup registers if we are a floppy drive, in all cases
	pop		es							; if it is not a floppy drive, these values will not be put in INTPACK
	mov		di, AH8h_FloppyDPT
%endif
	;; fall-through
		
.MidGame:		
	call	RamVars_GetCountOfKnownDrivesToAX		; assume hard disk for now, will discard if for floppies

	test	byte [bp+IDEPACK.intpack+INTPACK.dl], 080h
	jnz		.Done
		
	mov		[bp+IDEPACK.intpack+INTPACK.bl], bl

	mov		[bp+IDEPACK.intpack+INTPACK.es], es
	mov		[bp+IDEPACK.intpack+INTPACK.di], di		

	call	FloppyDrive_GetCountToAX

.Done:	
	mov		ah, dh
		
	mov		[bp+IDEPACK.intpack+INTPACK.cx], cx
	xchg	[bp+IDEPACK.intpack+INTPACK.dx], ax		; recover DL for BDA last status byte determination

	xor		ah, ah
%ifdef MODULE_SERIAL_FLOPPY
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH_ALHasDriveNumber			
%else
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif


;--------------------------------------------------------------------
; Returns L-CHS parameters for drive and total hard disk count.
;
; AH8h_GetDriveParameters
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...254)
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
AH8h_GetDriveParameters:
	call	AccessDPT_GetLCHStoAXBLBH
	; Fall to .PackReturnValues

;--------------------------------------------------------------------
; Packs L-CHS values to INT 13h, AH=08h return values.
;
; .PackReturnValues
;	Parameters:
;		AX:		Number of L-CHS cylinders available (1...1024)
;		BL:		Number of L-CHS heads (1...255)
;		BH:		Number of L-CHS sectors per track (1...63)
;		DS:		RAMVARS segment
;	Returns:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...254)
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
.PackReturnValues:
	dec		ax						; AX = Number of last cylinder
	dec		bx						; BL = Number of last head
	xchg	cx, ax
	xchg	cl, ch					; CH = Last cylinder bits 0...7
	eROR_IM	cl, 2					; CL bits 6...7 = Last cylinder bits 8...9
	or		cl, bh					; CL bits 0...5 = Sectors per track
	mov		dh, bl					; DH = Maximum head number

%ifdef MODULE_SERIAL_FLOPPY
	mov		bl,[di+DPT.bFlagsHigh]
%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS             ; not sure why this is needed for preprocessor-only
	eSHR_IM	bl,FLGH_DPT_SERIAL_FLOPPY_TYPE_FIELD_POSITION
%endif
%endif		
	ret

%ifdef MODULE_SERIAL_FLOPPY
;
; Floppy Disk Parameter Table.  There is no way to specify more than one of these
; for any given system, so no way to make this drive or media specific.
; So we return fixed values out of the ROM for callers who might be expecting this information.
;
; On AT systems, we return the information for a 1.44 MB disk, 
; and on XT systems, we return the information for a 360 KB disk.
;
AH8h_FloppyDPT:
%ifdef USE_AT
	db		0ah << 4 | 0fh			; Offset 0: Drive timings, 1.44MB values
%else
	db		0dh << 4 | 0fh			; Offset 0: Drive timings, 360KB values
%endif

	db		1h << 1 | 0				; Offset 1: Typical values of 1 for head load time
									;           DMA used (although it actually is not, but is more restrctive)
	db		25h						; Offset 2: Inactiviy motor turn-off delay, 
									; 			Typical value of 25h for 2 second delay
	db		02h						; Offset 3: Sector size, always 512

%ifdef USE_AT
	db		12h						; Offset 4: Sectors per track, 1.44MB value
	db		1bh						; Offset 5: Sector gap, 1.44MB value
%else
	db		09h						; Offset 4: Sectors per track, 360KB value
	db		2ah						; Offset 5: Sector gap, 360KB value
%endif

	db		0ffh					; Offset 6: Data length

%ifdef USE_AT
	db		6ch						; Offset 7: Format gap length, 1.44MB value
%else
	db		50h						; Offset 7: Format gap length, 360KB value
%endif

	db		0f6h					; Offset 8: Fill byte for format
	db		0fh						; Offset 9: Head setting time
	db		08h						; Offset A: Wait for motor startpu time

%ifdef USE_AT
	db		79						; Offset B: Maximum track number, 1.44MB value
	db		0						; Offset C: Data transfer rate, 1.44MB value
	db		4						; Offset D: Diskette CMOS drive type, 1.44MB value
%else
	db		39						; Offset B: Maximum track number, 360KB value
	db		80h						; Offset C: Data transfer rate, 360KB value
	db		1						; Offset D: Diskette CMOS drive type, 360KB value
%endif
%endif
