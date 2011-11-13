; Project name	:	XTIDE Univeral BIOS Configurator
; Description	:	Functions for loading and saving BIOS image file.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Saves changes to loaded BIOS image file if user wants to do so.
;
; BiosFile_SaveUnsavedChanges
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_SaveUnsavedChanges:
	push	ds
	push	di
	push	si

	; Check if saving is needed
	test	WORD [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_UNSAVED
	jz		SHORT .Return
	test	WORD [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_FILELOADED
	jz		SHORT .Return

	; Ask if user wants to save
	push	cs
	pop		ds
	push	cs
	pop		es
	call	BiosFile_DoesUserWantToSaveChanges
	jnc		SHORT .Return

	; Write file
	mov		si, 80h									; DS:SI points to default DTA (DOS PSP:80h)
	mov		di, g_cfgVars+CFGVARS.rgbEepromBuffers	; ES:DI points to data to save
	call	EEPROM_GenerateChecksum
	call	BiosFile_SaveFile
	jc		SHORT .Return							; Return if error

	; Update unsaved status
	and		WORD [cs:g_cfgVars+CFGVARS.wFlags], ~FLG_CFGVARS_UNSAVED
ALIGN JUMP_ALIGN
.Return:
	pop		si
	pop		di
	pop		ds
	ret

;--------------------------------------------------------------------
; Asks does user want to save changes to BIOS image file.
;
; BiosFile_DoesUserWantToSaveChanges
;	Parameters:
;		ES:		String segment
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user wants to save changes
;				Cleared if used does not want to save changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_DoesUserWantToSaveChanges:
	mov		bl, WIDTH_DLG			; Dialog width
	mov		di, g_szDlgSaveChanges	; ES:DI points to string to display
	jmp		Menu_ShowYNDlg


;--------------------------------------------------------------------
; Saves loaded BIOS image to a file.
;
; BiosFile_SaveFile
;	Parameters:
;		DS:SI:	Ptr to DTA for selected file
;		ES:DI:	Ptr to data to save
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Cleared if file saved successfully
;				Set if any error
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_SaveFile:
	; Open file
	mov		al, VAL_FACCS_WRITE	; Open for writing
	lea		dx, [si+DTA.szFile]	; DS:DX points to ASCIZ file name
	call	File_Open
	jc		SHORT BiosFile_DisplayFileErrorMessage

	; Save file
	mov		cx, [cs:g_cfgVars+CFGVARS.wEepromSize]
	call	File_Write
	jc		SHORT BiosFile_DisplayFileErrorMessage

	; Close file
	jmp		SHORT BiosFile_Close


;--------------------------------------------------------------------
; Loads file selected with BiosFile_SelectFile.
;
; BiosFile_LoadFile
;	Parameters:
;		DS:SI:	Ptr to DTA for selected file
;		ES:DI:	Ptr to buffer where to load file
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CX:		EEPROM size in bytes
;		CF:		Cleared if file loaded successfully
;				Set if any error
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_LoadFile:
	; Open file
	mov		al, VAL_FACCS_READ	; Open for reading
	lea		dx, [si+DTA.szFile]	; DS:DX points to ASCIZ file name
	call	File_Open
	jc		SHORT BiosFile_DisplayFileErrorMessage

	; Load file to buffer
	call	BiosFile_GetFileSizeToCX
	jc		SHORT BiosFile_DisplayFileSizeErrorMessage
	call	File_Read
	jc		SHORT BiosFile_DisplayFileErrorMessage

	; Close file
BiosFile_Close:
	call	File_Close
	jc		SHORT BiosFile_DisplayFileErrorMessage
	ret


;--------------------------------------------------------------------
; Returns size for selected file and makes sure it is not too large.
;
; BiosFile_GetFileSizeToCX
;	Parameters:
;		DS:SI:	Ptr to DTA for selected file
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CX:		File size in bytes
;		CF:		Set if file was too large
;				Cleared if supported size
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_GetFileSizeToCX:
	mov		cx, [si+DTA.dwFileSize+2]	; High word of file size to CX
	test	cx, cx						; File larger than 65535 bytes? (clears CF)
	mov		cx, [si+DTA.dwFileSize]		; Low word of file size to CX
	jnz		SHORT .TooLargeFile
	cmp		cx, MAX_EEPROM_SIZE			; Too large?
	ja		SHORT .TooLargeFile
	stc
.TooLargeFile:							; CF is always cleared when jumping to here
	cmc									; So we invert it
	ret


;--------------------------------------------------------------------
; Displays error messages related to loading files.
;
; BiosFile_DisplayFileErrorMessage
; BiosFile_DisplayFileSizeErrorMessage
;	Parameters:
;		AX:		DOS File I/O error code (BiosFile_DisplayFileErrorMessage only)
;		DS:SI:	Ptr to DTA for selected file
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set since error
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
BiosFile_DisplayFileErrorMessage:
	call	File_GetErrStr		; Error string to ES:DI
	jmp		SHORT BiosFile_DisplayErrorMessage
BiosFile_DisplayFileSizeErrorMessage:
	push	cs
	pop		es
	mov		di, g_szErrFileSize
BiosFile_DisplayErrorMessage:
	mov		bl, WIDTH_DLG		; Dialog width
	call	Menu_ShowMsgDlg
	stc
	ret


;--------------------------------------------------------------------
; Selects BIOS file to be loaded.
;
; BiosFile_SelectFile
;	Parameters:
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		DS:SI:	Ptr to DTA for selected file
;		CF:		Set if file selected successfully
;				Cleared if user cancellation
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_SelectFile:
	push	di
	push	cs								; Copy string segment...
	pop		es								; ...to ES
	mov		di, [di+MENUPAGEITEM.szDialog]	; ES:DI points to info string
	mov		si, g_szFileSearch				; DS:SI points to file search string
	mov		bl, WIDTH_DLG					; Dialog width
	call	Menu_ShowFileDlg				; Get DTA to DS:SI
	pop		di
	ret
