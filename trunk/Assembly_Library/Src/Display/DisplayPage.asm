; Project name	:	Assembly Library
; Description	:	Functions for managing display page.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DisplayPage_SetFromAL
;	Parameters:
;		AL:		New display page
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN DISPLAY_JUMP_ALIGN
DisplayPage_SetFromAL:
	xor		ah, ah
	mul		WORD [VIDEO_BDA.wBytesPerPage]		; AX = Offset to page
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], ax
	ret
%endif


;--------------------------------------------------------------------
; DisplayPage_GetColumnsToALandRowsToAH
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		AL:		Number of columns in selected text mode
;		AH:		Number of rows in selected text mode
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN DISPLAY_JUMP_ALIGN
DisplayPage_GetColumnsToALandRowsToAH:
	mov		al, [VIDEO_BDA.wColumns]		; 40 or 80
	mov		ah, 25							; Always 25 rows on standard text modes
	ret


;--------------------------------------------------------------------
; DisplayPage_SynchronizeToHardware
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN DISPLAY_JUMP_ALIGN
DisplayPage_SynchronizeToHardware:
	xor		dx, dx
	mov		ax, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition]
	div		WORD [VIDEO_BDA.wBytesPerPage]	; AX = Page

	cmp		al, [VIDEO_BDA.bActivePage]
	je		SHORT .Return					; Same page, no need to synchronize
	mov		ah, SELECT_ACTIVE_DISPLAY_PAGE
	int		BIOS_VIDEO_INTERRUPT_10h
.Return:
	ret
