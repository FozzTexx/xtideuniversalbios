; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing drive detection strings.

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
; DetectPrint_InitializeDisplayContext
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
DetectPrint_InitializeDisplayContext:
	JMP_DISPLAY_LIBRARY InitializeDisplayContext


%ifdef MODULE_HOTKEYS
;--------------------------------------------------------------------
; DetectPrint_GetSoftwareCoordinatesToAX
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
DetectPrint_GetSoftwareCoordinatesToAX:
	JMP_DISPLAY_LIBRARY GetSoftwareCoordinatesToAX
%endif


;--------------------------------------------------------------------
; DetectPrint_StartDetectWithMasterOrSlaveStringInCXandIdeVarsInCSBP
;	Parameters:
;		CS:CX:	Ptr to "Master" or "Slave" string
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
DetectPrint_StartDetectWithMasterOrSlaveStringInCXandIdeVarsInCSBP:
	mov		ax, [cs:bp+IDEVARS.wBasePort]   ; for IDE: AX=port address, DH=.bDevice
	; fall through to DetectPrint_StartDetectWithAutodetectedBasePortInAXandIdeVarsInCSBP

;--------------------------------------------------------------------
; DetectPrint_StartDetectWithAutodetectedBasePortInAXandIdeVarsInCSBP
;	Parameters:
;		AX:		Base Port Address
;		CS:CX:	Ptr to "Master" or "Slave" string
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
DetectPrint_StartDetectWithAutodetectedBasePortInAXandIdeVarsInCSBP:
	mov		dx, [cs:bp+IDEVARS.bDevice-1]   ; for Serial: AL=port address>>2, AH=baud rate
											;			  DL=COM number character, DH=.bDevice
	push	bp								; setup stack for call to
	mov		bp, sp							; BootMenuPrint_FormatCSSIfromParamsInSSBP

	push 	cx								; Push "Master" or "Slave"

	mov		cl, (g_szDetectPort-$$) & 0xff	; Setup print string for standard IDE
											; Note that we modify only the low order bits of CX a lot here,
											; saving code space rather than reloading CX completely.
											; This optimization requires that all the g_szDetect* strings are
											; on the same 256 byte page, which is checked in strings.asm.

%ifdef MODULE_SERIAL
	cmp		dh, DEVICE_SERIAL_PORT		  	; Check if this is a serial device

	jnz		.pushAndPrint					; CX = string to print, AX = port address, DX won't be used

	mov		cl, (g_szDetectCOM-$$) & 0xff	; Setup print string for COM ports
	push	cx								; And push now.  We use the fact that format strings can contain
											; themselves format strings.

	push	dx								; Push COM number character
											; If the string is going to be "Auto", we will push a NULL (zero)
											; here for the COM port number, which will be eaten by the
											; print routine (DisplayPrint_CharacterFromAL), resulting in
											; just "COM" being printed without a character after it.

 	mov		cl, (g_szDetectCOMAuto-$$) & 0xff	; Setup secondary print string for "Auto"

	test	dl, dl							; Check if serial port "Auto"
	jz		.pushAndPrintSerial				; CX = string to print, AX and DX won't be used

	mov		cl, (g_szDetectCOMLarge-$$) & 0xff	; Setup secondary print string for "COMn/xx.yK"

	mov		al,ah							; baud rate divisor to AL
	cbw										; clear AH, AL will always be less than 128
	xchg	si,ax							; move AX to SI for divide
	mov		ax,1152							; baud rate to display is 115200/divisor, the "00" is handled
											; in the print strings
	cwd										; clear top 16-bits of dividend
	div		si								; and divide...  Now AX = baud rate/100, DX = 0 (always a clean divide)

	mov		si,10							; Now separate the whole portion from the fractional for "K" display
	div		si								; and divide...  Now AX = baud rate/1000, DX = low order digit

	cmp		ax,si							; < 10: "2400", "9600", etc.; >= 10: "19.2K", "38.4K", etc.
	jae		.pushAndPrintSerial

	mov		cl, (g_szDetectCOMSmall-$$) & 0xff	; Setup secondary print string for "COMn/XXy00"

.pushAndPrintSerial:
.pushAndPrint:
%endif

	push	cx								; Push print string
	push	ax								; Push high order digits, or port address, or N/A
	push	dx								; Push low order digit, or N/A

	mov		si, g_szDetectOuter				; Load SI with default wrapper string "IDE %s at %s: "

	jmp		SHORT DetectPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; DetectPrint_DriveNameFromDrvDetectInfoInESBX
;	Parameters:
;		ES:BX:	Ptr to DRVDETECTINFO (if drive found)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
DetectPrint_DriveNameFromDrvDetectInfoInESBX:
	push	bp
	mov		bp,sp
	lea		si,[bx+DRVDETECTINFO.szDrvName]
	push	si
	mov		si,g_szDriveName
	jmp		SHORT DetectPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; Prints BIOS name and segment address where it is found.
;
; DetectPrint_RomFoundAtSegment
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
DetectPrint_RomFoundAtSegment:
	mov		si, g_szRomAt
	mov		di, cs						; BIOS segment address, for later inclusion in the output, parameterized
										; so that it can be a different value when using .BootMenuEntry

.BootMenuEntry:
	push	bp
	mov		bp, sp

%ifndef USE_186
	mov		ax, ROMVARS.szTitle
	push	ax
	push	di							; BIOS segment
	add		al, ROMVARS.szVersion - ROMVARS.szTitle
	push	ax
%else
	; szTitle and szVersion have the high order byte of their addresses zero,
	; so these push instructions are only 2 bytes
	;
	push	ROMVARS.szTitle
	push	di							; BIOS segment
	push	ROMVARS.szVersion
%endif

	jmp		SHORT DetectPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; DetectPrint_FailedToLoadFirstSector
;	Parameters:
;		AH:		INT 13h error code
;	Returns:
;		CF:		Set
;	Corrupts registers:
;		AX, CX, SI, DI
;--------------------------------------------------------------------
DetectPrint_FailedToLoadFirstSector:
	push	bp
	mov		bp, sp
	eMOVZX	cx, ah
	push	cx					; Push INT 13h error code
	mov		si, g_szReadError
	jmp		SHORT DetectPrint_FormatCSSIfromParamsInSSBP	; Sets CF


;--------------------------------------------------------------------
; DetectPrint_TryToBootFromDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DH, SI, DI
;--------------------------------------------------------------------
DetectPrint_TryToBootFromDL:
	push	bp
	mov		bp, sp

%ifdef MODULE_DRIVEXLATE

	call	DriveXlate_ToOrBack	; DL = Untranslated Drive number
	mov		dh, dl
	call	DriveXlate_ToOrBack	; DL = Translated Drive number

	call	DriveXlate_ConvertDriveNumberFromDLtoDriveLetter	; DL = Translated letter
	xchg	dl, dh
	call	DriveXlate_ConvertDriveNumberFromDLtoDriveLetter	; DL = Untranslated letter
	push	dx
	xchg	dl, dh
	push	dx

	call	DriveXlate_ConvertDriveLetterInDLtoDriveNumber	; Restore DL

%else
	ePUSH_T	ax, ' '			; No drive translation so print space

	; Get boot drive letters
	call	FloppyDrive_GetCountToAX
	mov		ah, 'A'			; AH = First Floppy Drive letter (always 'A')
	add		al, ah
	MAX_U	al, 'C'			; AL = First Hard Drive letter ('C', 'D', or 'E')
	test	dl, dl
	eCMOVNS	al, ah
	push	ax

%endif ; MODULE_DRIVEXLATE

	mov		si, g_szTryToBoot
	jmp		SHORT DetectPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; DetectPrint_NullTerminatedStringFromCSSI
; DetectPrint_NullTerminatedStringFromCSSIandSetCF
;	Parameters:
;		CS:SI:	Ptr to NULL terminated string to print
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
DetectPrint_NullTerminatedStringFromCSSI:
DetectPrint_NullTerminatedStringFromCSSIandSetCF:
;
; We send all CSSI strings through the Format routine for the case of
; compressed strings, but this doesn't hurt in the non-compressed case either
; (perhaps a little slower, but shouldn't be noticeable to the user)
; and results in smaller code size.
;
	push	bp
	mov		bp,sp
	; Fall to DetectPrint_FormatCSSIfromParamsInSSBP

;--------------------------------------------------------------------
; DetectPrint_FormatCSSIfromParamsInSSBP
;	Parameters:
;		CS:SI:	Ptr to string to format
;		BP:		SP before pushing parameters
;	Returns:
;		BP:		Popped from stack
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
DetectPrint_FormatCSSIfromParamsInSSBP:
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	stc				; Successful return from menu event
	pop		bp
	ret
