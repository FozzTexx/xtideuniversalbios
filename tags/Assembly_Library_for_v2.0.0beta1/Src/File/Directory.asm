; Project name	:	Assembly Library
; Description	:	Functions for accessing directories.


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Directory_GetDiskTransferAreaAddressToDSSI
;	Parameters:
;		Nothing
;	Returns:
;		DS:SI:	Ptr to DTA
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Directory_GetDiskTransferAreaAddressToDSSI:
	push	es
	push	bx

	mov		ah, GET_DISK_TRANSFER_AREA_ADDRESS
	int		DOS_INTERRUPT_21h
	push	es
	pop		ds
	mov		si, bx

	pop		bx
	pop		es
	ret


;--------------------------------------------------------------------
; Directory_ChangeToPathFromDSSI
;	Parameters:
;		DS:SI:	Ptr to NULL terminated path (max 64 bytes)
;	Returns:
;		AX:		Error code
;		CF:		Cleared if success
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Directory_ChangeToPathFromDSSI:
	xchg	dx, si		; Path now in DS:DX
	mov		ah, SET_CURRENT_DIRECTORY
	int		DOS_INTERRUPT_21h
	xchg	si, dx
	ret


;--------------------------------------------------------------------
; Directory_WriteCurrentPathToDSSI
;	Parameters:
;		DS:SI:	Ptr to destination buffer (64 bytes)
;	Returns:
;		AX:		Error code
;		CF:		Cleared if success
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Directory_WriteCurrentPathToDSSI:
	push	dx

	mov		ah, GET_CURRENT_DIRECTORY	; GET_CURRENT_DIRECTORY = 47h
	cwd									; Default drive (00h)
	int		DOS_INTERRUPT_21h

	pop		dx
	ret


;--------------------------------------------------------------------
; Directory_GetMatchCountToAXforSearchStringInDSSIwithAttributesInCX
;	Parameters:
;		CX:		File attributes
;		DS:SI:	NULL terminated search string (may include path and wildcards)
;	Returns:
;		AX:		Number of matching files found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Directory_GetMatchCountToAXforSearchStringInDSSIwithAttributesInCX:
	push	dx
	xor		dx, dx				; Zero counter
	call	Directory_UpdateDTAForFirstMatchForDSSIwithAttributesInCX
	jc		SHORT .NoMoreFilesFound
ALIGN JUMP_ALIGN
.FindNextFile:
	inc		dx					; Increment match count
	call	Directory_UpdateDTAForNextMatchUsingPreviousParameters
	jnc		SHORT .FindNextFile
ALIGN JUMP_ALIGN
.NoMoreFilesFound:
	xchg	ax, dx				; Match count to AX
	pop		dx
	ret


;--------------------------------------------------------------------
; Directory_UpdateDTAForFirstMatchForDSSIwithAttributesInCX
;	Parameters:
;		CX:		File attributes
;		DS:SI:	NULL terminated search string (may include path and wildcards)
;	Returns:
;		AX:		Error code
;		CF:		Cleared if success
;				Set if error
;		Disk Transfer Area (DTA) will be updated
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Directory_UpdateDTAForFirstMatchForDSSIwithAttributesInCX:
	xchg	dx, si							; Search string now in DS:DX
	mov		ax, FIND_FIRST_MATCHING_FILE<<8	; Zero AL (special flag for APPEND)
	int		DOS_INTERRUPT_21h
	xchg	si, dx
	ret


;--------------------------------------------------------------------
; Directory_UpdateDTAForNextMatchUsingPreviousParameters
;	Parameters:
;		Nothing (Parameters from previous call to
;				Directory_UpdateDTAForFirstMatchForDSSIwithAttributesInCX are used)
;	Returns:
;		AX:		Error code
;		CF:		Cleared if success
;				Set if error
;		Disk Transfer Area (DTA) will be updated
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Directory_UpdateDTAForNextMatchUsingPreviousParameters:
	mov		ah, FIND_NEXT_MATCHING_FILE
	int		DOS_INTERRUPT_21h
	ret
