; File name		:	DialogFile.asm
; Project name	:	Assembly Library
; Created date	:	6.9.2010
; Last update	:	12.10.2010
; Author		:	Tomi Tilli
; Description	:	Displays file dialog.


CURRENTDIR_CHARACTERS	EQU		002Eh
UPDIR_CHARACTERS		EQU		2E2Eh

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogFile_GetFileNameWithIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to FILE_DIALOG_IO
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogFile_GetFileNameWithIoInDSSI:
	mov		bx, FileEventHandler
	mov		BYTE [si+FILE_DIALOG_IO.bUserCancellation], TRUE
	jmp		Dialog_DisplayWithDialogInputInDSSIandHandlerInBX


;--------------------------------------------------------------------
; FileEventHandler
;	Common parameters for all events:
;		BX:			Menu event (anything from MENUEVENT struct)
;		SS:BP:		Ptr to DIALOG
;	Common return values for all events:
;		CF:			Set if event processed
;					Cleared if event not processed
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileEventHandler:
	jmp		[cs:bx+.rgfnEventHandlers]


ALIGN JUMP_ALIGN
.ItemSelectedFromCX:
	call	LoadItemStringBufferToESDI
	call	Memory_CopyESDItoDSSI
	call	ItemLineSplitter_GetLineToDSSIandLengthToCXfromStringInDSSIwithIndexInCX
	jmp		ParseSelectionFromItemLineInDSSI


ALIGN JUMP_ALIGN
.RefreshInformation:
	call	GetInfoLinesToCXandDialogFlagsToAX
	mov		si, [cs:.rgszInfoStringLookup]
	xor		bx, bx
	xchg	dx, ax
ALIGN JUMP_ALIGN
.InfoLineLoop:
	shr		dl, 1
	jnc		SHORT .CheckNextFlag
	mov		si, [cs:bx+.rgszInfoStringLookup]
	push	bx
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	pop		bx
ALIGN JUMP_ALIGN
.CheckNextFlag:
	inc		bx
	inc		bx
	loop	.InfoLineLoop
	stc						; Event processed
	ret


ALIGN WORD_ALIGN
.rgszInfoStringLookup:
	dw		g_szChangeDrive
	dw		g_szSelectDirectory
	dw		g_szCreateNew

.rgfnEventHandlers:
istruc MENUEVENT
	at	MENUEVENT.InitializeMenuinitFromDSSI,	dw	InitializeMenuinitFromSSBP
	at	MENUEVENT.ExitMenu,						dw	Dialog_EventNotHandled
	at	MENUEVENT.IdleProcessing,				dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemHighlightedFromCX,		dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemSelectedFromCX,			dw	.ItemSelectedFromCX
	at	MENUEVENT.KeyStrokeInAX,				dw	HandleFunctionKeyFromAH
	at	MENUEVENT.RefreshTitle,					dw	Dialog_EventRefreshTitle
	at	MENUEVENT.RefreshInformation,			dw	.RefreshInformation
	at	MENUEVENT.RefreshItemFromCX,			dw	Dialog_EventRefreshItemFromCX
iend


;--------------------------------------------------------------------
; InitializeMenuinitFromSSBP
;	Parameters:
;		DS:SI:		Ptr to MENUINIT to initialize (also points to DIALOG)
;		SS:BP:		Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializeMenuinitFromSSBP:
	call	LoadItemStringBufferToESDI
	call	CreateStringFromCurrentDirectoryContentsToESDI
	call	LoadItemStringBufferToESDI
	call	SortDirectoryContentsStringFromESDIwithCountInCX
	call	Memory_CopySSBPtoDSSI
	xor		ax, ax
	call	Dialog_EventInitializeMenuinitFromDSSIwithHighlightedItemInAX
	call	GetInfoLinesToCXandDialogFlagsToAX
	mov		[bp+MENUINIT.bInfoLines], cl
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	mov		[bp+MENUINIT.bHeight], ah				; Always max height
	mov		WORD [bp+MENU.wFirstVisibleItem], 0
	ret


;--------------------------------------------------------------------
; LoadItemStringBufferToESDI
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		ES:DI:	Ptr to item string buffer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LoadItemStringBufferToESDI:
	les		di, [bp+DIALOG.fpDialogIO]
	les		di, [es:di+FILE_DIALOG_IO.fszItemBuffer]
	ret


;--------------------------------------------------------------------
; CreateStringFromCurrentDirectoryContentsToESDI
;	Parameters:
;		ES:DI:	Buffer where to create item string
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		CX:		Number of files or directories found
;	Corrupts registers:
;		AX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateStringFromCurrentDirectoryContentsToESDI:
	lds		si, [bp+DIALOG.fpDialogIO]
	eMOVZX	cx, BYTE [si+FILE_DIALOG_IO.bFileAttributes]
	lds		si, [si+FILE_DIALOG_IO.fpFileFilterString]
	call	Directory_UpdateDTAForFirstMatchForDSSIwithAttributesInCX
	rcr		cx, 1			; Store CF
	call	.ClearDLifInRootDirectory
	call	Directory_GetDiskTransferAreaAddressToDSSI
	rcl		cx, 1			; Restore CF
	xor		cx, cx			; Clear file/directory count
	; Fall to .FindMatchingFilesAndWriteThemToESDI

;--------------------------------------------------------------------
; .FindMatchingFilesAndWriteThemToESDI
;	Parameters:
;		CX:		Initial directory count
;		DL:		Zero if root directory selected
;		DS:SI:	Ptr to DTA with first matching file
;		ES:DI:	Ptr to destination string buffer
;	Returns:
;		CX:		Incremented by number of files/directories found
;	Corrupts registers:
;		AX, DX, DI
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
.FindMatchingFilesAndWriteThemToESDI:
	jc		SHORT TerminateESDIwithNull
	call	AppendFileToBufferInESDIfromDtaInDSSI
	call	Directory_UpdateDTAForNextMatchUsingPreviousParameters
	jmp		SHORT .FindMatchingFilesAndWriteThemToESDI

;--------------------------------------------------------------------
; .ClearDLifInRootDirectory
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;		ES:DI:	Ptr to destination string buffer
;	Returns:
;		DL:		Cleared if in root directory
;				Set if in any other directory
;	Corrupts registers:
;		AX, SI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ClearDLifInRootDirectory:
	call	Memory_CopyESDItoDSSI
	call	Directory_WriteCurrentPathToDSSI
	mov		dl, [si]
	ret


;--------------------------------------------------------------------
; TerminateESDIwithNull
;	Parameters:
;		ES:DI:	Ptr to destination string buffer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
TerminateESDIwithNull:
	xor		ax, ax
	stosb
	ret


;--------------------------------------------------------------------
; AppendFileToBufferInESDIfromDtaInDSSI
;	Parameters:
;		CX:		Files/directores found
;		DL:		Zero if root directory selected
;		DS:SI:	Ptr to DTA containing file information
;		ES:DI:	Ptr to destination string buffer
;	Returns:
;		CX:		Incremented by number of files/directories found
;		DI:		Updated for next file
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AppendFileToBufferInESDIfromDtaInDSSI:
	call	.FilterCurrentDirectory			; We never want "."
	call	.FilterUpDirectoryWhenInRoot	; No ".." when in root directory
	inc		cx								; Nothing filtered so increment files/directories
	; Fall to .PrepareBufferFormattingAndFormatFromDTAinDSSI

;--------------------------------------------------------------------
; .PrepareBufferFormattingAndFormatFromDTAinDSSI
;	Parameters:
;		DS:SI:	Ptr to DTA containing file information
;		ES:DI:	Ptr to destination string buffer
;	Returns:
;		DI:		Updated for next file
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
.PrepareBufferFormattingAndFormatFromDTAinDSSI:
	push	bp
	push	si
	push	cx
	mov		bx, di
	CALL_DISPLAY_LIBRARY PushDisplayContext
	mov		cx, -1
	CALL_DISPLAY_LIBRARY PrepareOffScreenBufferInESBXwithLengthInCX

	call	.FormatFileOrDirectoryToBufferFromDTAinDSSI

	CALL_DISPLAY_LIBRARY GetCharacterPointerToBXAX
	xchg	bx, ax
	CALL_DISPLAY_LIBRARY PopDisplayContext
	mov		di, bx
	pop		cx
	pop		si
	pop		bp
	ret

;--------------------------------------------------------------------
; .FormatFileOrDirectoryToBufferFromDTAinDSSI
;	Parameters:
;		DS:SI:	Ptr to DTA containing file information
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FormatFileOrDirectoryToBufferFromDTAinDSSI:
	mov		bp, sp
	lea		ax, [si+DTA.szFile]

	test	BYTE [si+DTA.bFileAttributes], FLG_FILEATTR_DIRECTORY
	jnz		SHORT .FormatDirectory
	; Fall to .FormatFile

;--------------------------------------------------------------------
; .FormatFile
;	Parameters:
;		BP:		SP before pushing formatting parameters
;		DS:AX:	Far pointer to file name
;		DS:SI:	Ptr to DTA containing file information
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, BP
;--------------------------------------------------------------------
.FormatFile:
	; Convert file name to lower case
	xchg	si, ax
	mov		dx, StringProcess_ConvertToLowerCase
	call	StringProcess_DSSIwithFunctionInDX
	xchg	ax, si

	; Push parameters for file name
	push	ax				; Push directory name offset
	push	ds				; Push directory name segment

	; Push parameters for file size
	mov		ax, [si+DTA.dwFileSize]
	mov		dx, [si+DTA.dwFileSize+2]
	xor		bx, bx
	xor		cx, cx
	call	Size_GetSizeToAXAndCharToDLfromBXDXAXwithMagnitudeInCX
	mov		cl, 'i'
	cmp		dl, ' '
	eCMOVE	cl, dl
	push	ax
	push	dx
	push	cx

	; Format to buffer
	mov		si, g_szFileFormat
	jmp		SHORT .FormatStringInCSSIandReturn

;--------------------------------------------------------------------
; .FormatDirectory
;	Parameters:
;		BP:		SP before pushing formatting parameters
;		DS:AX:	Far pointer to directory name
;		DS:SI:	Ptr to DTA containing file information
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FormatDirectory:
	push	ax				; Push directory name offset
	push	ds				; Push directory name segment
	mov		ax, g_szSub
	cmp		WORD [si+DTA.szFile], UPDIR_CHARACTERS
	eCMOVE	ax, g_szUp
	push	ax
	mov		si, g_szDirectoryFormat
ALIGN JUMP_ALIGN
.FormatStringInCSSIandReturn:
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret

;--------------------------------------------------------------------
; .FilterCurrentDirectory
; .FilterUpDirectoryWhenInRoot
;	Parameters:
;		DL:		Zero if root directory selected
;		DS:SI:	Ptr to DTA containing file information
;	Returns:
;		Nothing
;		Returns from AppendFileToBufferInESDIfromDtaInDSSI when filtering
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FilterCurrentDirectory:
	cmp		WORD [si+DTA.szFile], CURRENTDIR_CHARACTERS
	jne		SHORT .ReturnWithoutFiltering
	add		sp, BYTE 2		; Remove return address from stack
	ret

ALIGN JUMP_ALIGN
.FilterUpDirectoryWhenInRoot:
	test	dl, dl			; Set ZF if root directory selected
	jnz		SHORT .ReturnWithoutFiltering
	cmp		WORD [si+DTA.szFile], UPDIR_CHARACTERS
	jne		SHORT .ReturnWithoutFiltering
	add		sp, BYTE 2		; Remove return address from stack
ALIGN JUMP_ALIGN, ret
.ReturnWithoutFiltering:
	ret


;--------------------------------------------------------------------
; SortDirectoryContentsStringFromESDIwithCountInCX
;	Parameters:
;		CX:		Number of files and directories
;		ES:DI:	Buffer containing directory contents string
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SortDirectoryContentsStringFromESDIwithCountInCX:
	call	Memory_ExchangeDSSIwithESDI
	mov		bx, .FileStringComparator
	xchg	dx, cx
	mov		cx, FILE_STRING_LENGTH
	jmp		Sort_ItemsFromDSSIwithCountInDXsizeInCXandComparatorInBX

;--------------------------------------------------------------------
; .FileStringComparator
;	Parameters:
;		CX:		Item size in bytes
;		DS:SI:	Ptr to first item to compare
;		ES:DI:	Ptr to second item to compare
;	Returns:
;		FLAGS:	Signed comparition between first and second item
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FileStringComparator:
	push	di
	push	si
	push	cx
	push	bx

	mov		bx, FILE_STRING_LENGTH-2			; Zero BH
	cmp		WORD [si], UPDIR_CHARACTERS
	je		SHORT .ForceValueFromDSSItoBeLess
	mov		bl, [si+bx]
	cmp		bl, [es:di+FILE_STRING_LENGTH-2]	; 'B' for files, 'R' for directories
	jne		SHORT .ForceValueFromDSSItoBeMoreOrLess
	repe cmpsb									; Two directories or two files

ALIGN JUMP_ALIGN
.ReturnFromComparison:
	pop		bx
	pop		cx
	pop		si
	pop		di
	ret
ALIGN JUMP_ALIGN
.ForceValueFromDSSItoBeMoreOrLess:
	ja		SHORT .ForceValueFromDSSItoBeLess	; Directory in SI, file in DI
	xchg	bl, bh
	; Fall to ForceValueFromDSSItoBeLess
ALIGN JUMP_ALIGN
.ForceValueFromDSSItoBeLess:
	cmp		bh, bl
	jmp		SHORT .ReturnFromComparison


;--------------------------------------------------------------------
; GetInfoLinesToCXandDialogFlagsToAX
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		AX:		Dialog flags
;		CX:		Number of info lines to be displayed
;	Corrupts registers:
;		SI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetInfoLinesToCXandDialogFlagsToAX:
	xor		ax, ax
	call	GetDialogFlagsToAL
	jmp		Bit_GetSetCountToCXfromAX

;--------------------------------------------------------------------
; GetDialogFlagsToAL
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		AL:		Dialog flags
;	Corrupts registers:
;		SI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetDialogFlagsToAL:
	lds		si, [bp+DIALOG.fpDialogIO]
	mov		al, [si+FILE_DIALOG_IO.bDialogFlags]
	ret


;--------------------------------------------------------------------
; ParseSelectionFromItemLineInDSSI
;	Parameters:
;		DS:SI:	Ptr to char buffer containing file or directory to be selected
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ParseSelectionFromItemLineInDSSI:
	mov		ax, [si]
	cmp		ax, UPDIR_CHARACTERS
	je		SHORT .ChangeToUpdir
	call	Char_IsUpperCaseLetterInAL
	jc		SHORT .ParseAndChangeToSubdirInDSSI
	; Fall to .ParseAndSelectFileFromDSSI

;--------------------------------------------------------------------
; .ParseAndSelectFileFromDSSI
;	Parameters:
;		DS:SI:	NULL terminated string selected from dialog
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing (exits dialog)
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
.ParseAndSelectFileFromDSSI:
	les		di, [bp+DIALOG.fpDialogIO]
	add		di, BYTE FILE_DIALOG_IO.szFile
	mov		cx, FILENAME_BUFFER_SIZE-1
	call	Memory_CopyCXbytesFromDSSItoESDI
	xor		ax, ax
	stosb						; Terminate with NULL
	jmp		SHORT CloseFileDialogAfterSuccessfullSelection

;--------------------------------------------------------------------
; .ChangeToUpdir
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ChangeToUpdir:
	push	cs
	pop		ds
	mov		si, g_szUpdir
	jmp		SHORT .ChangeDirectoryToDSSI

;--------------------------------------------------------------------
; .ParseAndChangeToSubdirInDSSI
;	Parameters:
;		DS:SI:	NULL terminated string selected from dialog
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ParseAndChangeToSubdirInDSSI:
	mov		BYTE [si+12], NULL	; Terminate with NULL (unnecessary spaces do not matter)
.ChangeDirectoryToDSSI:
	call	Directory_ChangeToPathFromDSSI
	; Fall to RefreshFilesToDisplay

;--------------------------------------------------------------------
; RefreshFilesToDisplay
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RefreshFilesToDisplay:
	call	InitializeMenuinitFromSSBP
	jmp		MenuInit_RefreshMenuWindow


;--------------------------------------------------------------------
; HandleFunctionKeyFromAH
;	Parameters:
;		AH:		Scancode for function key
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI, BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HandleFunctionKeyFromAH:
	call	GetDialogFlagsToAL
	cmp		ah, KEY_FILEDIALOG_NEW_FILE_OR_DIR
	je		SHORT HandleFunctionKeyForCreatingNewFileOrDirectory
	cmp		ah, KEY_FILEDIALOG_SELECT_DIRECTORY
	je		SHORT HandleFunctionKeyForSelectingDirectoryInsteadOfFile
	cmp		ah, KEY_FILEDIALOG_CHANGE_DRIVE
	je		SHORT HandleFunctionKeyForDriveChange
ReturnWithoutHandlingKeystroke:
	clc		; Event not processed
	ret


;--------------------------------------------------------------------
; HandleFunctionKeyForCreatingNewFileOrDirectory
;	Parameters:
;		AL:		File dialog flags
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Closes file dialog
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HandleFunctionKeyForCreatingNewFileOrDirectory:
	test	al, FLG_FILEDIALOG_NEW
	jz		SHORT ReturnWithoutHandlingKeystroke

	mov		cx, STRING_DIALOG_IO_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	.InitializeStringDialogIoInDSSIforInputtingFileName

	CALL_MENU_LIBRARY GetStringWithIoInDSSI
	mov		al, [si+STRING_DIALOG_IO.bUserCancellation]
	add		sp, BYTE STRING_DIALOG_IO_size
	test	al, al		; User cancellation?
	jnz		SHORT ReturnWithoutHandlingKeystroke
	jmp		CloseFileDialogAfterSuccessfullSelection

ALIGN JUMP_ALIGN
.InitializeStringDialogIoInDSSIforInputtingFileName:
	call	InitializeNullStringsToDialogInputInDSSI
	mov		WORD [si+DIALOG_INPUT.fszTitle], g_szEnterNewFileOrDirectory
	mov		WORD [si+STRING_DIALOG_IO.fnCharFilter], NULL
	mov		WORD [si+STRING_DIALOG_IO.wBufferSize], FILENAME_BUFFER_SIZE
	les		ax, [bp+DIALOG.fpDialogIO]
	add		ax, BYTE FILE_DIALOG_IO.szFile
	mov		[si+STRING_DIALOG_IO.fpReturnBuffer], ax
	mov		[si+STRING_DIALOG_IO.fpReturnBuffer+2], es
	ret


;--------------------------------------------------------------------
; HandleFunctionKeyForSelectingDirectoryInsteadOfFile
;	Parameters:
;		AL:		File dialog flags
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Closes file dialog
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HandleFunctionKeyForSelectingDirectoryInsteadOfFile:
	test	al, FLG_FILEDIALOG_DIRECTORY
	jz		SHORT ReturnWithoutHandlingKeystroke
	; Fall to CloseFileDialogAfterSuccessfullSelection

;--------------------------------------------------------------------
; CloseFileDialogAfterSuccessfullSelection
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing (exits dialog)
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CloseFileDialogAfterSuccessfullSelection:
	lds		di, [bp+DIALOG.fpDialogIO]
	mov		BYTE [di+FILE_DIALOG_IO.bUserCancellation], FALSE
	jmp		MenuInit_CloseMenuWindow


;--------------------------------------------------------------------
; HandleFunctionKeyForDriveChange
;	Parameters:
;		AL:		File dialog flags
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HandleFunctionKeyForDriveChange:
	test	al, FLG_FILEDIALOG_DRIVES
	jz		SHORT ReturnWithoutHandlingKeystroke

	call	.ShowDriveSelectionDialogAndGetDriveNumberToDL
	jnc		SHORT RefreshFilesToDisplay
	call	Drive_SetDefaultFromDL
	jmp		SHORT RefreshFilesToDisplay

;--------------------------------------------------------------------
; .ShowDriveSelectionDialogAndGetDriveNumberToDL
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		DL:		Drive selected by user
;		CF:		Set if new drive selected
;				Cleared if selection cancelled by user
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ShowDriveSelectionDialogAndGetDriveNumberToDL:
	mov		cx, DIALOG_INPUT_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	.InitializeDialogInputInDSSIforDriveSelection
	call	DialogSelection_GetSelectionToAXwithInputInDSSI
	add		sp, BYTE DIALOG_INPUT_size
	cmp		ax, BYTE NO_ITEM_SELECTED	; Clear CF if equal
	jne		SHORT .ConvertDriveNumberToDLfromItemIndexInAX
	ret

ALIGN JUMP_ALIGN
.InitializeDialogInputInDSSIforDriveSelection:
	call	InitializeNullStringsToDialogInputInDSSI
	call	LoadItemStringBufferToESDI
	mov		WORD [si+DIALOG_INPUT.fszTitle], g_szSelectNewDrive
	mov		[si+DIALOG_INPUT.fszItems], di
	mov		[si+DIALOG_INPUT.fszItems+2], es
	call	Drive_GetFlagsForAvailableDrivesToDXAX
	; Fall to .GenerateDriveSelectionStringToESDIfromDriveFlagsInDXAX

;--------------------------------------------------------------------
; .GenerateDriveSelectionStringToESDIfromDriveFlagsInDXAX
;	Parameters:
;		DX:AX:	Drive letter flags
;		ES:DI:	Ptr to item string buffer
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, DI, ES
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
.GenerateDriveSelectionStringToESDIfromDriveFlagsInDXAX:
	cld
	xchg	cx, ax
	mov		ax, 3A41h		; A:
ALIGN JUMP_ALIGN
.BitShiftLoop:
	shr		dx, 1
	rcr		cx, 1
	jnc		SHORT .CheckIfMoreDrivesLeft
	stosw
	mov		BYTE [es:di], LF
	inc		di
ALIGN JUMP_ALIGN
.CheckIfMoreDrivesLeft:
	inc		ax				; Next drive letter
	mov		bx, dx
	or		bx, cx
	jnz		SHORT .BitShiftLoop
	jmp		TerminateESDIwithNull

;--------------------------------------------------------------------
; .ConvertDriveNumberToDLfromItemIndexInAX
;	Parameters:
;		AX:		Selected drive item	
;	Returns:
;		DL:		Drive number
;		CF:		Set since drive selected
;	Corrupts registers:
;		AX, CX, DH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ConvertDriveNumberToDLfromItemIndexInAX:
	mov		ah, -1
	xchg	cx, ax
	call	Drive_GetFlagsForAvailableDrivesToDXAX
ALIGN JUMP_ALIGN
.BitScanLoop:
	shr		dx, 1
	rcr		ax, 1
	inc		ch				; Increment drive number
	sbb		cl, 0			; Decrement selection index
	jnc		SHORT .BitScanLoop
	mov		dl, ch
	stc						; Drive selected by user
	ret


;--------------------------------------------------------------------
; InitializeNullStringsToDialogInputInDSSI
;	Parameters:
;		DS:SI:	Ptr to DIALOG_INPUT
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializeNullStringsToDialogInputInDSSI:
	mov		ax, g_szNull
	mov		[si+DIALOG_INPUT.fszTitle], ax
	mov		[si+DIALOG_INPUT.fszTitle+2], cs
	mov		[si+DIALOG_INPUT.fszItems], ax
	mov		[si+DIALOG_INPUT.fszItems+2], cs
	mov		[si+DIALOG_INPUT.fszInfo], ax
	mov		[si+DIALOG_INPUT.fszInfo+2], cs
	ret
