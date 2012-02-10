; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing drive detection strings.

; Section containing code
SECTION .text

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
	push	bp
	mov		bp, sp
	mov		si, g_szRomAt
	ePUSH_T	ax, ROMVARS.szTitle			; Bios title string
	push	cs							; BIOS segment

DetectPrint_BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay:
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; DetectPrint_StartDetectWithMasterOrSlaveStringInAXandIdeVarsInCSBP
;	Parameters:
;		CS:CX:	Ptr to "Master" or "Slave" string
;		CS:BP:	Ptr to IDEVARS
;       SI:		Ptr to template string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI, CX
;--------------------------------------------------------------------
DetectPrint_StartDetectWithMasterOrSlaveStringInAXandIdeVarsInCSBP:

	mov		ax, [cs:bp+IDEVARS.wPort]    	; for IDE: AX=port address, DH=.bDevice
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
	jz		.pushAndPrint					; CX = string to print, AX and DX won't be used

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
	jae		.pushAndPrint

	mov		cl, (g_szDetectCOMSmall-$$) & 0xff	; Setup secondary print string for "COMn/XXy00"

.pushAndPrint:
	push	cx								; Push print string
	push	ax								; Push high order digits, or port address, or N/A
	push	dx								; Push low order digit, or N/A

	mov		si, g_szDetectOuter				; Finally load SI with wrapper string "IDE %s at %s: "

	jmp		short DetectPrint_BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay


;--------------------------------------------------------------------
; DetectPrint_DriveNameFromBootnfoInESBX
;	Parameters:
;		ES:BX:	Ptr to BOOTNFO (if drive found)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI
;--------------------------------------------------------------------
DetectPrint_DriveNameFromBootnfoInESBX:
	push	di
	push	bx

	lea		si, [bx+BOOTNFO.szDrvName]
	mov		bx, es
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromBXSI
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters

	pop		bx
	pop		di
	ret

