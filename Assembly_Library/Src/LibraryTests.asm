; File name		:	LibraryTests.asm
; Project name	:	Assembly Library
; Created date	:	27.6.2010
; Last update	:	12.10.2010
; Author		:	Tomi Tilli
; Description	:	Tests for Assembly Library.
;					This file should not be included when using the library on
;					some other project.		

; Include .inc files
%define INCLUDE_MENU_DIALOGS
%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!


; Section containing code
SECTION .text

; Program first instruction.
ORG	100h						; Code starts at offset 100h (DOS .COM)
Start:
	jmp		LibraryTests_Start

; Include library sources
%include "AssemblyLibrary.asm"


;--------------------------------------------------------------------
; Program start
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LibraryTests_Start:	
	CALL_DISPLAY_LIBRARY InitializeDisplayContext
	CALL_DISPLAY_LIBRARY ClearScreen

	;call	LibraryTests_Sort
	;call	LibraryTests_ForDisplayLibrary
	;call	LibraryTests_ForKeyboardLibrary
	call	LibraryTests_ForMenuLibrary

	; Exit to DOS
	;mov		ax, CURSOR_XY(1, 1)
	;CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	CALL_DISPLAY_LIBRARY SynchronizeDisplayContextToHardware
	mov 	ax, 4C00h			; Exit to DOS
	int 	21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ALIGN JUMP_ALIGN
LibraryTests_ForMenuLibrary:
	mov		[cs:g_dialogInputOutput+DIALOG_INPUT.fszTitle+2], cs
	mov		[cs:g_dialogInputOutput+DIALOG_INPUT.fszItems+2], cs
	mov		[cs:g_dialogInputOutput+DIALOG_INPUT.fszInfo+2], cs

	mov		bx, .MenuEventHandler
	call	MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX
	ret

ALIGN JUMP_ALIGN
.MenuEventHandler:
	jmp		[cs:bx+.rgfnMenuEvents]
.NotHandled:
	clc		; Not handled so clear
	ret

ALIGN JUMP_ALIGN
.InitializeMenu:
	mov		WORD [si+MENUINIT.wTimeoutTicks], 10000 / 55	; 10 seconds
	mov		WORD [si+MENUINIT.wItems], 51
	mov		BYTE [si+MENUINIT.bWidth], 40
	mov		BYTE [si+MENUINIT.bHeight], 20
	mov		BYTE [si+MENUINIT.bTitleLines], TEST_MENU_TITLE_LINES
	mov		BYTE [si+MENUINIT.bInfoLines], TEST_MENU_INFO_LINES
	mov		WORD [si+MENUINIT.wHighlightedItem], 1
	stc
	ret

ALIGN JUMP_ALIGN
.RefreshTitle:
	mov		si, .szMenuTitle
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	stc
	ret
.szMenuTitle:
	db		"Simple test program for Assembly Library. Can be used to find bugs.",NULL

ALIGN JUMP_ALIGN
.RefreshInformation:
	push	bp
	mov		bp, sp
	mov		si, .szInfoTitle
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	pop		bp
	stc
	ret
.szInfoTitle:
	db		"Information line 1,",LF,CR,
	db		"Information line 2. ",
	db		"This comes (12) right after Information line 2.",NULL

ALIGN JUMP_ALIGN
.RefreshItemFromCX:
	cmp		cx, TEST_MENU_VALID_ITEMS
	jb		SHORT .PrintKnownItem

	push	bp
	mov		si, .szItem
	mov		bp, sp
	push	cx				; Item index
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	pop		bp
	stc
	ret
.szItem:
	db	"This is item %d.",NULL
.PrintKnownItem:
	mov		si, cx
	shl		si, 1
	mov		si, [cs:si+.rgszItems]
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	stc
	ret

ALIGN JUMP_ALIGN
.ItemSelectedFromCX:
	push	cs
	pop		ds
	cmp		cx, TEST_MENU_VALID_ITEMS
	jae		SHORT .ReturnWithoutHandling
	mov		bx, cx
	shl		bx, 1
	jmp		[bx+.rgfnSelectionHandler]
.ReturnWithoutHandling:
	stc
	ret

ALIGN WORD_ALIGN
.rgfnSelectionHandler:
	dw		.ExitMenuByItem
	dw		.ToggleTitle
	dw		.ToggleInfo
	dw		.ShowMessageDialogWithUnformattedText
	dw		.AskWordFromUser
	dw		.AskStringFromUser
	dw		.AskSelectionFromUser
	dw		.AskFileFromUser
	dw		.TestProgressBar


ALIGN JUMP_ALIGN
.ExitMenuByItem:
	CALL_MENU_LIBRARY Close
.ExitMenuByMenuLibrary:
	stc
	ret

ALIGN JUMP_ALIGN
.ToggleTitle:
	mov		al, [bp+MENUINIT.bTitleLines]
	xor		al, TEST_MENU_TITLE_LINES
	CALL_MENU_LIBRARY SetTitleHeightFromAL
	jmp		SHORT .RefreshMenuWindow
ALIGN JUMP_ALIGN
.ToggleInfo:
	mov		al, [bp+MENUINIT.bInfoLines]
	xor		al, TEST_MENU_INFO_LINES
	CALL_MENU_LIBRARY SetInformationHeightFromAL
.RefreshMenuWindow:
	CALL_MENU_LIBRARY RestartTimeout
	CALL_MENU_LIBRARY RefreshWindow
	stc
	ret

ALIGN JUMP_ALIGN
.ShowMessageDialogWithUnformattedText:
	mov		di, g_szVeryLongString
	jmp		.ShowDialogWithStringInCSDI

ALIGN JUMP_ALIGN
.AskWordFromUser:
	mov		si, g_dialogInputOutput
	mov		BYTE [si+WORD_DIALOG_IO.bNumericBase], 10
	mov		WORD [si+WORD_DIALOG_IO.wMin], 10
	mov		WORD [si+WORD_DIALOG_IO.wMax], 20
	CALL_MENU_LIBRARY GetWordWithIoInDSSI

	mov		ax, [si+WORD_DIALOG_IO.wReturnWord]
	mov		di, g_szBuffer
	call	.FormatWordFromAXtoStringBufferInCSDI
	call	.ShowDialogWithStringInCSDI
	stc
	ret

ALIGN JUMP_ALIGN
.AskStringFromUser:
	mov		si, g_dialogInputOutput
	mov		WORD [si+STRING_DIALOG_IO.fnCharFilter], NULL
	mov		WORD [si+STRING_DIALOG_IO.wBufferSize], 17
	mov		WORD [si+STRING_DIALOG_IO.fpReturnBuffer], g_szBuffer
	mov		[si+STRING_DIALOG_IO.fpReturnBuffer+2], cs
	CALL_MENU_LIBRARY GetStringWithIoInDSSI

	mov		di, g_szBuffer
	call	.ShowDialogWithStringInCSDI
	stc
	ret

ALIGN JUMP_ALIGN
.AskSelectionFromUser:
	mov		si, g_dialogInputOutput
	mov		WORD [si+DIALOG_INPUT.fszItems], .szSelections
	CALL_MENU_LIBRARY GetSelectionToAXwithInputInDSSI

	mov		di, g_szBuffer
	call	.FormatWordFromAXtoStringBufferInCSDI
	call	.ShowDialogWithStringInCSDI
	stc
	ret
.szSelections:
	db		"Cancel",LF
	db		"Yes",LF
	db		"No",NULL

ALIGN JUMP_ALIGN
.AskFileFromUser:
	mov		si, g_dialogInputOutput
	mov		WORD [si+FILE_DIALOG_IO.fszItemBuffer], g_szBuffer
	mov		BYTE [si+FILE_DIALOG_IO.bDialogFlags], FLG_FILEDIALOG_DIRECTORY | FLG_FILEDIALOG_NEW | FLG_FILEDIALOG_DRIVES
	mov		BYTE [si+FILE_DIALOG_IO.bFileAttributes], FLG_FILEATTR_DIRECTORY | FLG_FILEATTR_ARCHIVE
	mov		WORD [si+FILE_DIALOG_IO.fpFileFilterString], .szAllFiles
	mov		[si+FILE_DIALOG_IO.fpFileFilterString+2], cs
	CALL_MENU_LIBRARY GetFileNameWithIoInDSSI
	cmp		BYTE [g_dialogInputOutput+FILE_DIALOG_IO.bUserCancellation], TRUE
	je		SHORT .FileSelectionCancelled

	mov		di, g_dialogInputOutput + FILE_DIALOG_IO.szFile
	call	.ShowDialogWithStringInCSDI
.FileSelectionCancelled:
	stc
	ret
.szAllFiles:
	db		"*.*",NULL


ALIGN JUMP_ALIGN
.FormatWordFromAXtoStringBufferInCSDI:
	push	bp
	push	di
	mov		si, di
	xchg	cx, ax
	CALL_DISPLAY_LIBRARY PushDisplayContext

	mov		bx, cs
	mov		ax, si
	CALL_DISPLAY_LIBRARY SetCharacterPointerFromBXAX
	mov		bl, ATTRIBUTES_NOT_USED
	mov		ax, BUFFER_OUTPUT_WITH_CHAR_ONLY
	CALL_DISPLAY_LIBRARY SetCharOutputFunctionFromAXwithAttribFlagInBL
	lea		ax, [si+STRING_BUFFER_SIZE]
	CALL_DISPLAY_LIBRARY SetCharacterOutputParameterFromAX

	mov		si, .szFormatWord
	mov		bp, sp
	push	cx
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	mov		al, NULL
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL	; Terminate buffer with NULL

	CALL_DISPLAY_LIBRARY PopDisplayContext
	pop		di
	pop		bp
	ret
.szFormatWord:
	db		"Integer %d selected!",NULL


ALIGN JUMP_ALIGN
.ShowDialogWithStringInCSDI:
	push	cs
	pop		ds
	mov		si, g_dialogInputOutput
	mov		WORD [si+DIALOG_INPUT.fszItems], di
	CALL_MENU_LIBRARY DisplayMessageWithInputInDSSI
	stc
	ret


ALIGN JUMP_ALIGN
.TestProgressBar:
	push	cs
	pop		ds
	mov		si, g_dialogInputOutput
	mov		WORD [si+PROGRESS_DIALOG_IO.wCurrentProgressValue], 0
	mov		WORD [si+PROGRESS_DIALOG_IO.wMaxProgressValue], 500
	mov		WORD [si+PROGRESS_DIALOG_IO.wMinProgressValue], 0
	mov		WORD [si+PROGRESS_DIALOG_IO.fnTaskWithParamInDSSI], .ProgressTaskWithParamInDSSI
	mov		ax, 500			; Counter for progress task
	CALL_MENU_LIBRARY StartProgressTaskWithIoInDSSIandParamInDXAX
	stc
	ret

ALIGN JUMP_ALIGN
.ProgressTaskWithParamInDSSI:
	mov		ax, 50000					; 50 millisec delay
	call	Delay_MicrosecondsFromAX
	dec		si
	CALL_MENU_LIBRARY SetUserDataFromDSSI
	mov		ax, 500
	sub		ax, si
	push	si
	CALL_MENU_LIBRARY SetProgressValueFromAX
	pop		si
	test	si, si
	jnz		.ProgressTaskWithParamInDSSI
	ret
	
	

ALIGN WORD_ALIGN
.rgfnMenuEvents:
	dw		.InitializeMenu			; .InitializeMenuinitToDSSI
	dw		.ExitMenuByMenuLibrary	; .ExitMenu
	dw		.NotHandled				; .IdleProcessing
	dw		.NotHandled				; .ItemHighlightedFromCX
	dw		.ItemSelectedFromCX		; .ItemSelectedFromCX
	dw		.NotHandled				; .KeyStrokeInDX
	dw		.RefreshTitle			; .RefreshTitle
	dw		.RefreshInformation		; .RefreshInformation
	dw		.RefreshItemFromCX		; .RefreshItemFromCX

.rgszItems:
	dw		.szExitMenu
	dw		.szToggleTitle
	dw		.szToggleInfo
	dw		.szShowMessage
	dw		.szAskWord
	dw		.szAskString
	dw		.szAskSelection
	dw		.szAskFile
	dw		.szTestProgress
.szExitMenu:	db	"Exit menu",NULL
.szToggleTitle:	db	"Toggle title",NULL
.szToggleInfo:	db	"Toggle information",NULL
.szShowMessage:	db	"Display unformatted message",NULL
.szAskWord:		db	"Input word",NULL
.szAskString:	db	"Input string",NULL
.szAskSelection:db	"Display selection dialog",NULL
.szAskFile:		db	"Display file dialog",NULL
.szTestProgress:db	"Display progress bar",NULL
TEST_MENU_VALID_ITEMS			EQU		9
TEST_MENU_TITLE_LINES			EQU		2
TEST_MENU_INFO_LINES			EQU		3



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ALIGN JUMP_ALIGN
LibraryTests_ForKeyboardLibrary:
	mov		ax, CURSOR_XY(0, 6)
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	call	ReadUnsignedDecimalInteger
	call	ReadHexadecimalWord
	ret


ReadUnsignedDecimalInteger:
	mov		si, .szEnterUnsignedWord
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	CALL_DISPLAY_LIBRARY SynchronizeDisplayContextToHardware	; Move hardware cursor

	mov		bx, 10			; Numeric base
	call	Keyboard_ReadUserInputtedWordWhilePrinting

	mov		si, .szWordEntered
	mov		bp, sp
	push	ax
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret
.szWordEntered:
	db	". Word entered: %u",LF,CR,NULL
.szEnterUnsignedWord:
	db	"Enter unsigned word: ",NULL


ReadHexadecimalWord:
	mov		si, .szEnterHexadecimalWord
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	CALL_DISPLAY_LIBRARY SynchronizeDisplayContextToHardware	; Move hardware cursor

	mov		bx, 16			; Numeric base
	call	Keyboard_ReadUserInputtedWordWhilePrinting

	mov		si, .szWordEntered
	mov		bp, sp
	push	ax
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret
.szWordEntered:
	db	". Word entered: %x",LF,CR,NULL
.szEnterHexadecimalWord:
	db	"Enter hexadecimal word: ",NULL



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ALIGN JUMP_ALIGN
LibraryTests_ForDisplayLibrary:
	CALL_DISPLAY_LIBRARY PushDisplayContext
	call	PrintHorizontalRuler
	call	PrintVerticalRuler
	
	mov		al, COLOR_ATTRIBUTE(COLOR_BRIGHT_WHITE, COLOR_BLACK)
	CALL_DISPLAY_LIBRARY SetCharacterAttributeFromAL

	mov		ax, CURSOR_XY(0, 1)
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	call	PrintFormattedStrings

	CALL_DISPLAY_LIBRARY PopDisplayContext
	ret


PrintHorizontalRuler:
	mov		ax, CURSOR_XY(0, 0)
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	eMOVZX	cx, al
	mov		bx, 10<<8			; Divider 10 to BH
.ColumnNumberLoop:
	eMOVZX	ax, bl				; Column index to AX (0...79)
	div		bh					; AH = 0...9, AL = attribute
	mov		dx, ax
	inc		ax					; Increment attribute for non-black foreground
	CALL_DISPLAY_LIBRARY SetCharacterAttributeFromAL
	xchg	ax, dx
	mov		al, '0'
	add		al, ah				; AL = '0'...'9'
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL
	inc		bx					; Increment column index
	loop	.ColumnNumberLoop
	ret


PrintVerticalRuler:
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	eMOVZX	cx, ah				; Number of rows to CX
	dec		ax					; Last column
	xor		ah, ah
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX

	dec		cx					; Decrement rows to print last row outside loop
	mov		bx, 10<<8			; BH = 10 (divider), BL = 0 (row index)
	mov		si, .szVerticalRulerCharacter
.RowNumberLoop:
	call	.PrintRowNumberFromBL
	inc		bx					; Increment row index
	loop	.RowNumberLoop

	; Last row
	mov		si, .szLastVerticalRulerCharacter
.PrintRowNumberFromBL:
	eMOVZX	ax, bl				; Row index to AX (0...24)
	div		bh					; AH = 0...9, AL = attribute
	add		al, COLOR_GRAY		; Start from color GRAY
	mov		bp, sp				; Prepare BP for string formatting
	push	ax					; Push attribute
	eMOVZX	ax, ah
	push	ax					; Push row index
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret

.szVerticalRulerCharacter:
	db	"%A%u",LF,NULL
.szLastVerticalRulerCharacter:
	db	"%A%u",NULL


PrintFormattedStrings:
	call	.PrintIntegers
	call	.PrintHexadecimals
	call	.PrintCharacters
	call	.PrintStrings
	call	.RepeatChar
	ret

.PrintIntegers:
	mov		si, .szIntegers
	mov		bp, sp
	ePUSH_T	ax, COLOR_ATTRIBUTE(COLOR_RED, COLOR_BLACK)
	ePUSH_T	ax, -32768
	ePUSH_T	ax, -1
	ePUSH_T	ax, 0
	ePUSH_T	ax, 1
	ePUSH_T	ax, 65535
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret
.szIntegers:
	db	"Integers -32768, -1, 0, 1, 65535:          %A|%6-d|%6-d|%6-d|%6-d|%6-u|",LF,CR,NULL

.PrintHexadecimals:
	mov		si, .szHexadecimals
	mov		bp, sp
	ePUSH_T	ax, COLOR_ATTRIBUTE(COLOR_RED, COLOR_BLACK)
	ePUSH_T	ax, 0CACAh
	ePUSH_T	ax, 0FFFFh
	ePUSH_T	ax, 0
	ePUSH_T	ax, 5A5Ah
	ePUSH_T	ax, 0A5A5h
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret
.szHexadecimals:
	db	"Hexadecimals CACAh, FFFFh, 0, 5A5Ah, A5A5h:%A|%6-x|%6-x|%6-x|%6-x|%6-x|",LF,CR,NULL

.PrintCharacters:
	mov		si, .szCharacters
	mov		bp, sp
	ePUSH_T	ax, COLOR_ATTRIBUTE(COLOR_RED, COLOR_BLACK)
	ePUSH_T	ax, 'a'
	ePUSH_T	ax, 'B'
	ePUSH_T	ax, 'c'
	ePUSH_T	ax, 'D'
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret
.szCharacters:
	db	"Characters a, B, c, D, percent:            %A|%6c|%6c|%6c|%6c|%6%|",LF,CR,NULL

.PrintStrings:
	mov		si, .szStrings
	mov		bp, sp
	ePUSH_T	ax, COLOR_ATTRIBUTE(COLOR_RED, COLOR_BLACK)
	ePUSH_T	ax, .szCSSI
	ePUSH_T	ax, .szFar
	push	cs
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret
.szStrings:
	db	"Strings ",'"',"Hello CSSI",'"'," and ",'"',"Far",'"',":            %A|%20s|%13S|",LF,CR,NULL
.szCSSI:
	db	"Hello CSSI",NULL
.szFar:
	db	"Far",NULL
	
.RepeatChar:
	mov		si, .szRepeat
	mov		bp, sp
	ePUSH_T	ax, COLOR_ATTRIBUTE(COLOR_RED, COLOR_BLACK)
	ePUSH_T	ax, '-'
	ePUSH_T	ax, 36
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret
.szRepeat:
	db	"Repeating character '-':                   %A%t",LF,CR,NULL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LibraryTests_Sort:
	call	.PrintWords
	push	cs
	pop		ds
	mov		si, .rgwItems
	mov		dx, 7
	mov		cx, 2
	mov		bx, .Comparator
	call	Sort_ItemsFromDSSIwithCountInDXsizeInCXandComparatorInBX
	call	.PrintWords
	ret


.Comparator:
	push	ax
	mov		ax, [si]
	DISPLAY_DEBUG_CHARACTER 'I'
	DISPLAY_DEBUG_WORD_AND_WAIT_ANY_KEY ax, 16
	DISPLAY_DEBUG_CHARACTER ','
	DISPLAY_DEBUG_WORD_AND_WAIT_ANY_KEY [es:di], 16
	DISPLAY_DEBUG_CHARACTER ' '
	cmp		ax, [es:di]
	pop		ax
	ret

.PrintWords:
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
	mov		cx, 7
	push	cs
	pop		ds
	mov		si, .rgwItems
	mov		bx, 16
.Loop:
	lodsw
	CALL_DISPLAY_LIBRARY PrintSignedWordFromAXWithBaseInBX
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
	loop	.Loop
	ret


.rgwItems:
	dw		'['
	dw		'n'
	dw		'5'
	dw		'.'
	dw		']'
	dw		'a'
	dw		'A'



; Section containing initialized data
;SECTION .data

g_szDialogTitle:
	db		"This is a generic title for all dialogs.",NULL
g_szDialogInfo:
	db		"This is a generic information for all dialogs.",NULL
g_szVeryLongString:
	db		"This is a very long string containing multiple lines of text. This is needed "
	db		"so scroll bars and message dialog can be tested. This string does not use "
	db		"formatting so it should be simple to display this correctly. This string "
	db		"does, however, use newline characters. Lets change line right now!",LF,CR,
	db		"Well did it work? Let's try line feed alone",LF,"Well? "
	db		"Now two LFs:",LF,LF,"What happened? "
	db		"We could also see what two spaces does _  _. There was two spaces between "
	db		"underscores. Lets try three this time _   _. Well, did they work correctly? "
	db		"Too bad that LF, CR and BS (backspace) are the only supported control "
	db		"characters. Others don't either work or they break line splitting. "
	db		"This is the last sentence of this long string!",NULL

g_dialogInputOutput:
istruc DIALOG_INPUT
	at	DIALOG_INPUT.fszTitle,	dw	g_szDialogTitle
	at	DIALOG_INPUT.fszInfo,	dw	g_szDialogInfo
iend
	times	20	db	0


; Section containing uninitialized data
SECTION .bss

STRING_BUFFER_SIZE			EQU		100
g_szBuffer:
