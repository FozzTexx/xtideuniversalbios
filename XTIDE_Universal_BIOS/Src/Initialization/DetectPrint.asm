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
;		CS:AX:	Ptr to "Master" or "Slave" string
;		CS:BP:	Ptr to IDEVARS
;       SI:		Ptr to template string 
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI, CX
;--------------------------------------------------------------------
DetectPrint_StartDetectWithMasterOrSlaveStringInAXandIdeVarsInCSBP:
	push	bp
	mov		di, [cs:bp+IDEVARS.wPort]
%ifdef MODULE_SERIAL
	mov		cx, [cs:bp+IDEVARS.wSerialPackedPrintBaud]
%endif
		
	mov		bp, sp

	push 	ax							; Push "Master" or "Slave"
		
	push	di							; Push Port address or COM port number

%ifdef MODULE_SERIAL
;
; Baud rate is packed into one word:
;    High order 6 bits: number to add to '0' to get postfix character ('0' or 'K')
;    Low order 10 bits:	binary number to display (960, 240, 38, or 115)
;          To get 9600:	'0'<<10 + 960
;          To get 2400:	'0'<<10 + 240
;          To get 38K:	('K'-'0')<<10 + 38
;          To get 115K:	('K'-'0')<<10 + 115
;
	mov		ax,cx						; Unpack baud rate number
	and		ax,03ffh
	push	ax

	mov		al,ch						; Unpack baud rate postfix ('0' or 'K')
	eSHR_IM	al,2
	add		al,'0'
	push	ax
%endif
						
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



