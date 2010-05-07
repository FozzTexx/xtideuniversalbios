; File name		:	FlashMenu.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	29.4.2010
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
; Description	:	Flash menu.


; Flash error codes returned from progress bar task function
ERR_FLASH_SUCCESSFULL	EQU		0
ERR_FLASH_POLL_TIMEOUT	EQU		1


; Section containing initialized data
SECTION .data

; -Back to previous menu
; *Start flashing
; +SDP command (Enable)
; EEPROM address (D000h)
; Page size (1)
; Generate checksum byte (Y)

ALIGN WORD_ALIGN
g_MenuPageFlash:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,	db	6
iend
istruc MENUPAGEITEM	; Back to previous menu
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szPreviousMenu
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgBack
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgBack
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; Start flashing
	at	MENUPAGEITEM.fnActivate,	dw	FlashMenu_ActivateStartFlashing
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemFlashStart
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoFlashStart
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoFlashStart
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_SPECIAL
iend
istruc MENUPAGEITEM	; SDP command
	at	MENUPAGEITEM.fnActivate,	dw	FlashMenu_ActivateSdpCommand
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_LookupString
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.bSdpCommand
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageSdpCommand
	at	MENUPAGEITEM.rgszLookup,	dw	g_rgszSdpValueToString
	at	MENUPAGEITEM.szName,		dw	g_szItemFlashSDP
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoFlashSDP
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpFlashSDP
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
istruc MENUPAGEITEM	; EEPROM address
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetHexWordFromUserWithoutMarkingUnsaved
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.wEepromSegment
	at	MENUPAGEITEM.szName,		dw	g_szItemFlashAddr
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoFlashAddr
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoFlashAddr
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgFlashAddr
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_HEX_WORD
iend
istruc MENUPAGEITEM	; Page size
	at	MENUPAGEITEM.fnActivate,	dw	FlashMenu_ActivatePageSize
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.bPageSize
	at	MENUPAGEITEM.wValueMin,		dw	1
	at	MENUPAGEITEM.wValueMax,		dw	64
	at	MENUPAGEITEM.szName,		dw	g_szItemFlashPageSize
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoFlashPageSize
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpFlashPageSize
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgFlashPageSize
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend
istruc MENUPAGEITEM	; Generate checksum byte
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetBoolFromUserWithoutMarkingUnsaved
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.wFlags
	at	MENUPAGEITEM.wValueMask,	dw	FLG_CFGVARS_CHECKSUM
	at	MENUPAGEITEM.szName,		dw	g_szItemFlashChecksum
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoFlashChecksum
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpFlashChecksum
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgFlashChecksum
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; FlashMenu_ActivateSdpCommand
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_ActivateSdpCommand:
	call	MainPageItem_ActivateSubmenuForGettingLookupValueWithoutMarkingUnsaved
	jnc		SHORT .Return
	call	FormatTitle_RedrawMenuTitle
	stc
.Return:
	ret


;--------------------------------------------------------------------
; FlashMenu_ActivatePageSize
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_ActivatePageSize:
	call	MenuPageItem_GetByteFromUserWithoutMarkingUnsaved
	jnc		SHORT .Cancel
	eMOVZX	bx, BYTE [g_cfgVars+CFGVARS.bPageSize]
	eBSR	ax, bx					; AX = Index of highest order bit
	mov		cx, 1
	xchg	ax, cx
	shl		ax, cl					; AX = 1, 2, 4, 8, 16, 32 or 64
	mov		[g_cfgVars+CFGVARS.bPageSize], al
	stc
	ret
.Cancel:
	clc
	ret


;--------------------------------------------------------------------
; FlashMenu_ActivateStartFlashing
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_ActivateStartFlashing:
	test	WORD [g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_CHECKSUM
	jz		SHORT .CopyContentsForComparison
	call	EEPROM_GenerateChecksum
ALIGN JUMP_ALIGN
.CopyContentsForComparison:
	call	Flash_CopyCurrentContentsForComparison
	call	FlashMenu_InitializeFlashVars
	call	FlashMenu_CreateProgressDialogAndStartFlashing
	call	FlashMenu_ProcessFlashResults
	clc
	ret

;--------------------------------------------------------------------
; Initializes FLASHVARS.
;
; FlashMenu_InitializeFlashVars
;	Parameters:
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_InitializeFlashVars:
	; Total number of pages to write
	xor		dx, dx
	mov		ax, [g_cfgVars+CFGVARS.wEepromSize]		; DX:AX = Bytes to write
	eMOVZX	cx, BYTE [g_cfgVars+CFGVARS.bPageSize]
	div		cx										; AX = Total number of pages
	mov		[g_cfgVars+CFGVARS.flashVars+FLASHVARS.wTotalPages], ax
	mov		[g_cfgVars+CFGVARS.flashVars+FLASHVARS.wPagesLeft], ax

	; Number of pages to write before updating progress bar
	mov		cx, WIDTH_DLG-4
	div		cx										; AX = Number of pages before update
	mov		[g_cfgVars+CFGVARS.flashVars+FLASHVARS.wPagesBeforeDraw], ax

	; Zero offset since nothing written yet
	mov		WORD [g_cfgVars+CFGVARS.flashVars+FLASHVARS.wByteOffset], 0
	ret

;--------------------------------------------------------------------
; Shows progress bar dialog.
;
; FlashMenu_CreateProgressDialogAndStartFlashing
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Return code from progress bar task function
;	Corrupts registers:
;		BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_CreateProgressDialogAndStartFlashing:
	push	ds
	push	di
	push	si

	mov		bx, WIDTH_DLG | (5<<8)					; Height = 5 rows
	mov		si, g_cfgVars+CFGVARS.flashVars			; DS:SI points to FLASHVARS
	push	cs
	pop		es
	mov		di, FlashMenu_FlashProgressBarTask		; ES:DI points to progress bar task function
	call	Menu_ShowProgDlg

	pop		si
	pop		di
	pop		ds
	ret

;--------------------------------------------------------------------
; Progress bar task function for flashing.
; Cursor will be set to Title string location so progress dialog
; title string can be modified if so wanted.
; Remember to return with RETF instead of RET!
;
; FlashMenu_FlashProgressBarTask
;	Parameters:
;		DS:SI:	Pointer to FLASHVARS
;	Returns:
;		AX:		Error code if task completed (CF set)
;				Task completion percentage (0...100) if CF cleared
;		CF:		Set if task was completed or cancelled
;				Cleared if task must be continued
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_FlashProgressBarTask:
	call	FlashMenu_UpdateProgressBarTitle
	call	FlashMenu_FlashAllPagesBeforeUpdate
	jc		SHORT .Timeout
	call	FlashMenu_CalculateCompletionPercentage
	jc		SHORT .FlashComplete
	retf
ALIGN JUMP_ALIGN
.FlashComplete:
	mov		ax, ERR_FLASH_SUCCESSFULL
	retf
.Timeout:
	mov		ax, ERR_FLASH_POLL_TIMEOUT
	retf


;--------------------------------------------------------------------
; Updates progress bar dialog title string.
;
; FlashMenu_UpdateProgressBarTitle
;	Parameters:
;		DS:SI:	Pointer to FLASHVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_UpdateProgressBarTitle:
	push	si
	mov		ax, [si+FLASHVARS.wTotalPages]
	sub		ax, [si+FLASHVARS.wPagesLeft]			; AX=Pages written
	eMOVZX	dx, BYTE [g_cfgVars+CFGVARS.bPageSize]
	mul		dx										; AX=Bytes written

	push	WORD [g_cfgVars+CFGVARS.wEepromSize]	; EEPROM size
	push	ax										; Bytes written
	mov		si, g_szFlashProgress
	call	Print_Format
	add		sp, BYTE 4								; Clean stack
	pop		si
	ret

;--------------------------------------------------------------------
; Flashes pages until it is time to update progress bar.
;
; FlashMenu_FlashAllPagesBeforeUpdate
;	Parameters:
;		DS:SI:	Pointer to FLASHVARS
;	Returns:
;		CF:		Cleared if pages written successfully
;				Set if polling timeout
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
FlashMenu_FlashAllPagesBeforeUpdate:
	push	es
	push	bp
	push	di
	push	si

	mov		bp, si
	mov		dx, [si+FLASHVARS.wPagesBeforeDraw]
	call	FlashMenu_GetPointersToPageToFlash
	eMOVZX	ax, BYTE [g_cfgVars+CFGVARS.bSdpCommand]
	eMOVZX	cx, BYTE [g_cfgVars+CFGVARS.bPageSize]
ALIGN JUMP_ALIGN
.PageLoop:
	call	Flash_WritePage
	jc		SHORT .Return
	add		[ds:bp+FLASHVARS.wByteOffset], cx
	clc
	dec		WORD [ds:bp+FLASHVARS.wPagesLeft]
	jz		SHORT .Return		; Test since .wPagesBeforeDraw might write too much
	dec		dx
	jnz		SHORT .PageLoop
.Return:
	pop		si
	pop		di
	pop		bp
	pop		es
	ret

;--------------------------------------------------------------------
; Returns all pointers required for flashing.
;
; FlashMenu_GetPointersToPageToFlash
;	Parameters:
;		DS:SI:	Pointer to FLASHVARS
;	Returns:
;		DS:BX:	Pointer to comparison buffer
;		DS:SI:	Pointer to source data buffer
;		ES:DI:	Pointer to EEPROM
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_GetPointersToPageToFlash:
	mov		ax, [si+FLASHVARS.wByteOffset]
	call	EEPROM_GetComparisonBufferPointerToDSBX
	call	EEPROM_GetSourceBufferPointerToDSSI
	call	EEPROM_GetEepromPointerToESDI
	add		bx, ax
	add		si, ax
	add		di, ax
	ret


;--------------------------------------------------------------------
; Returns all pointers required for flashing.
;
; FlashMenu_GetFlashPointersToNextPage
;	Parameters:
;		DS:SI:	Pointer to FLASHVARS
;	Returns:
;		AX:		Completion percentage (0...100)
;		CF:		Set if all done
;				Cleared if not yet complete
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_CalculateCompletionPercentage:
	cmp		WORD [si+FLASHVARS.wPagesLeft], 0
	je		SHORT .FlashComplete
	mov		ax, 100
	mul		WORD [si+FLASHVARS.wPagesLeft]
	div		WORD [si+FLASHVARS.wTotalPages]		; AX = Percentage left to write
	mov		ah, 100
	sub		ah, al
	mov		al, ah
	xor		ah, ah								; AX = Percentage written (clears CF)
	ret
ALIGN JUMP_ALIGN
.FlashComplete:
	mov		ax, 100
	stc
	ret


;--------------------------------------------------------------------
; Processes results from flashing.
; Computer will be rebooted if PC expansion card BIOS was flashed.
;
; FlashMenu_ProcessFlashResults
;	Parameters:
;		AX:		Return code from progress bar task function
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_ProcessFlashResults:
	cmp		ax, ERR_FLASH_POLL_TIMEOUT
	je		SHORT FlashMenu_PollingTimeoutErrorDuringFlashing
	call	Flash_WasDataWriteSuccessfull
	jne		SHORT FlashMenu_DataVerifyErrorAfterFlashing
	; Fall to FlashMenu_EepromFlashedSuccessfully

;--------------------------------------------------------------------
; Computer will be rebooted if PC expansion card BIOS was flashed.
;
; FlashMenu_EepromFlashedSuccessfully
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
FlashMenu_EepromFlashedSuccessfully:
	cmp		WORD [g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wRomSign], 0AA55h
	je		SHORT .RebootSinceAllDone
	mov		WORD [di+MENUPAGEITEM.szDialog], g_szFlashDoneContinue
	jmp		MenuPageItem_DisplaySpecialFunctionDialog
ALIGN JUMP_ALIGN
.RebootSinceAllDone:
	mov		WORD [di+MENUPAGEITEM.szDialog], g_szFlashDoneReboot
	call	MenuPageItem_DisplaySpecialFunctionDialog
	mov		al, 0FEh				; System reset (AT+ keyboard controller)
	out		64h, al					; Reset computer (AT+)
	jmp		WORD 0F000h:0FFF0h		; Safe reset on XTs only

;--------------------------------------------------------------------
; Displays flash error messages.
;
; FlashMenu_PollingTimeoutErrorDuringFlashing
; FlashMenu_DataVerifyErrorAfterFlashing
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_PollingTimeoutErrorDuringFlashing:
	mov		WORD [di+MENUPAGEITEM.szDialog], g_szFlashTimeout
	jmp		MenuPageItem_DisplaySpecialFunctionDialog

ALIGN JUMP_ALIGN
FlashMenu_DataVerifyErrorAfterFlashing:
	mov		WORD [di+MENUPAGEITEM.szDialog], g_szFlashVerifyErr
	jmp		MenuPageItem_DisplaySpecialFunctionDialog
