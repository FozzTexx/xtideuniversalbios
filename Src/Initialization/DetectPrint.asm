; File name		:	DetectPrint.asm
; Project name	:	IDE BIOS
; Created date	:	28.3.2010
; Last update	:	9.4.2010
; Author		:	Tomi Tilli
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
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectPrint_RomFoundAtSegment:
	push	cs
	ePUSH_T	ax, ROMVARS.szTitle
	mov		si, g_szRomAt
	mov		dh, 4						; 4 bytes pushed to stack
	jmp		PrintString_JumpToFormat


;--------------------------------------------------------------------
; Displays IDE drive detection string for specific device.
;
; DetectPrint_StartingMasterDetect
; DetectPrint_StartingSlaveDetect
;	Parameters:
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectPrint_StartingMasterDetect:
	mov		ax, g_szMaster
	jmp		SHORT DetectPrint_StartingDriveDetect
ALIGN JUMP_ALIGN
DetectPrint_StartingSlaveDetect:
	mov		ax, g_szSlave
	; Fall to DetectPrint_StartingDriveDetect

;--------------------------------------------------------------------
; Displays IDE drive detection string.
;
; DetectPrint_StartingDriveDetect
;	Parameters:
;		AX:		Offset to "Master" or "Slave" string
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectPrint_StartingDriveDetect:
	push	WORD [cs:bp+IDEVARS.wPort]
	push	ax
	mov		si, g_szDetect
	mov		dh, 4						; 4 bytes pushed to stack
	jmp		PrintString_JumpToFormat


;--------------------------------------------------------------------
; Displays Detected Drive Name from BOOTVARS or
; drive not found string if no drive was found.
;
; DetectPrint_DriveNameOrNotFound
;	Parameters:
;		ES:BX:	Ptr to BOOTNFO (if drive found)
;		CF:		Cleared if drive found
;				Set it drive not found
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectPrint_DriveNameOrNotFound:
	jc		SHORT .PrintDriveNotFound
	lea		si, [bx+BOOTNFO.szDrvName]
	call	PrintString_FromES
	jmp		Print_Newline
ALIGN JUMP_ALIGN
.PrintDriveNotFound:
	mov		si, g_szNotFound
	jmp		PrintString_FromCS
