; File name		:	Display.inc
; Project name	:	AssemblyLibrary
; Created date	:	25.6.2010
; Last update	:	28.9.2010
; Author		:	Tomi Tilli
; Description	:	Defines for display library.
%ifndef DISPLAY_INC
%define DISPLAY_INC

;--------------------------------------------------------------------
; Display Library users need to use this macro since it will provide
; compatibility with future library versions.
;
; CALL_DISPLAY_LIBRARY
;	Parameters:
;		%1:			Function to call (functionName from DISPLAY_LIB)
;		Registers:	Depends on function to call
;	Returns:
;		Depends on function to call
;	Corrupts registers:
;		AX (unless used as a return register), DI
;--------------------------------------------------------------------
%macro CALL_DISPLAY_LIBRARY 1
	%ifidn %1, PushDisplayContext
		call	DisplayContext_Push
	%elifidn %1, PopDisplayContext
		call	DisplayContext_Pop
	%else
		mov		di, DISPLAY_LIB.%1
		call	Display_FunctionFromDI
	%endif
%endmacro


; Display library functions
struc DISPLAY_LIB
	.PushDisplayContext:
	.PopDisplayContext:
	.InitializeDisplayContext						resb	2

	.SetCharacterPointerFromBXAX					resb	2
	.SetCharOutputFunctionFromAXwithAttribFlagInBL	resb	2
	.SetCharacterOutputParameterFromAX				resb	2
	.SetCharacterAttributeFromAL					resb	2
	.SetCursorShapeFromAX							resb	2
	.SetCursorCoordinatesFromAX						resb	2
	.SetNewPageFromAL								resb	2
	.SynchronizeDisplayContextToHardware			resb	2

	.GetCharacterPointerToBXAX						resb	2
	.GetSoftwareCoordinatesToAX						resb	2
	.GetColumnsToALandRowsToAH						resb	2

	.FormatNullTerminatedStringFromCSSI				resb	2
	.PrintSignedWordFromAXWithBaseInBX				resb	2
	.PrintWordFromAXwithBaseInBX					resb	2
	.PrintCharBufferFromBXSIwithLengthInCX			resb	2
	.PrintNullTerminatedStringFromBXSI				resb	2
	.PrintNullTerminatedStringFromCSSI				resb	2
	.PrintRepeatedCharacterFromALwithCountInCX		resb	2
	.PrintCharacterFromAL							resb	2
	.PrintNewlineCharacters							resb	2
	.ClearAreaWithHeightInAHandWidthInAL			resb	2
	.ClearScreen									resb	2
endstruc

; Attribute flags for DISPLAY_LIB.SetCharacterOutputFunctionFromAXwithAttributeFlagInDL
ATTRIBUTES_NOT_USED							EQU		0
ATTRIBUTES_ARE_USED							EQU		FLG_CONTEXT_ATTRIBUTES

; Character output functions for DISPLAY_LIB.SetCharacterOutputFunctionFromAXwithAttributeFlagInDL
TELETYPE_OUTPUT_WITH_ATTRIBUTE				EQU		DisplayCharOut_TeletypeOutputWithAttribute
TELETYPE_OUTPUT_WITHOUT_ATTRIBUTE			EQU		DisplayCharOut_TeletypeOutput
TELETYPE_OUTPUT_USING_BIOS					EQU		DisplayCharOut_BiosTeletypeOutput
FAST_OUTPUT_WITH_ATTRIBUTE_ONLY				EQU		DisplayCharOut_Attribute
FAST_OUTPUT_WITH_CHAR_ONLY					EQU		DisplayCharOut_Character
FAST_OUTPUT_WITH_CHAR_AND_ATTRIBUTE			EQU		DisplayCharOut_CharacterWithAttribute
BUFFER_OUTPUT_WITH_CHAR_ONLY				EQU		DisplayCharOut_WriteCharacterToBuffer

DEFAULT_CHARACTER_OUTPUT					EQU		TELETYPE_OUTPUT_WITH_ATTRIBUTE


struc VIDEO_BDA
						resb	449h
	.bMode				resb	1		; 0:449h, Video, Mode
	.wColumns			resb	2		; 0:44Ah, Video, Number of columns
	.wBytesPerPage		resb	2		; 0:44Ch, Video, Total number of bytes per page
	.wPageOffset		resb	2		; 0:44Eh, Video, Current page offset
	.rgwCursors			resb	4		; 0:450h, Video, Cursor position, pages 0...1
	.displayContext		resb	12		; Our own display context (normally cursors for pages 2...7)
	.wCursorShape		resb	2		; 0:460h, Video, Cursor shape
	.bActivePage		resb	1		; 0:462h, Video, Active display page
	.wVideoPort			resb	2		; 0:463h, Video, I/O Port number base
	.bInternalModeReg	resb	1		; 0:465h, Video, Internal mode register
	.bColorPalette		resb	1		; 0:466h, Video, Color palette
endstruc

struc DISPLAY_CONTEXT
	.fpCursorPosition	resb	4	; Far pointer to cursor position in video memory
	.fnCharOut			resb	2	; Function to draw character with
	.wCharOutParam		resb	2	; User parameter for custom character output function
	.wCursorShape		resb	2	; Current cursor shape
	.bAttribute			resb	1	; Selected character attribute
	.bFlags				resb	1	; Display context flags
endstruc

; Display context flags
FLG_CONTEXT_ATTRIBUTES		EQU		(1<<0)	; Character output function uses attributes


; Text mode character attribute byte bits for CGA+ (color adapters)
FLG_COLOR_FORE_BLUE			EQU		(1<<0)
FLG_COLOR_FORE_GREEN		EQU		(1<<1)
FLG_COLOR_FORE_RED			EQU		(1<<2)
FLG_COLOR_FORE_INTENSITY	EQU		(1<<3)
FLG_COLOR_FORE_FONT_B		EQU		(1<<3)	; Select font set B (if available, EGA+)
FLG_COLOR_BACK_BLUE			EQU		(1<<4)
FLG_COLOR_BACK_GREEN		EQU		(1<<5)
FLG_COLOR_BACK_RED			EQU		(1<<6)
FLG_COLOR_BACK_INTENSITY	EQU		(1<<7)	; Intensity when blinking is disabled
FLG_COLOR_BLINK				EQU		(1<<7)	; Blinking color when enabled (enabled by default)

; CGA colors
%define COLOR_ATTRIBUTE(foreground, background)	( (foreground) | ((background)<<4) )
COLOR_BLACK					EQU		0
COLOR_BLUE					EQU		1
COLOR_GREEN					EQU		2
COLOR_CYAN					EQU		3
COLOR_RED					EQU		4
COLOR_MAGENTA				EQU		5
COLOR_BROWN					EQU		6
COLOR_WHITE					EQU		7		; Last background color if blinking enabled
COLOR_GRAY					EQU		8
COLOR_LIGHT_BLUE			EQU		9
COLOR_LIGHT_GREEN			EQU		10
COLOR_LIGHT_CYAN			EQU		11
COLOR_LIGHT_RED				EQU		12
COLOR_LIGHT_MAGENTA			EQU		13
COLOR_YELLOW				EQU		14
COLOR_BRIGHT_WHITE			EQU		15


; Text mode character attribute byte bits for MDA (monochrome adapters)
; (attributes 00h, 08h, 80h, 88h, 70h, 78h, F0h and F8h are exceptions)
FLG_MONO_UNDERLINE			EQU		(1<<1)
FLG_MONO_INTENSITY			EQU		(1<<3)
FLG_MONO_BLINK				EQU		(1<<7)

; Text mode character attribute bytes for MDA/Hercules (monochrome adapters)
; *Not displayed on some monitors
MONO_HIDDEN					EQU		00h		; Not displayed (same for 08h, 80h and 88h)
MONO_UNDERLINE				EQU		01h		; Underlined
MONO_NORMAL					EQU		07h		; Normal (white on black)
MONO_BRIGHT_UNDERLINE		EQU		09h		; High intensity, underlined
MONO_BRIGHT					EQU		0Fh		; High intensity
MONO_REVERSE				EQU		70h		; Reverse video (black on white)
MONO_REVERSE_DARK			EQU		78h		; (dark green on green)
MONO_BLINK					EQU		87h		; Blinking white on black*
MONO_BRIGHT_BLINK			EQU		8Fh		; Blinking high intensity*
MONO_REVERSE_BLINK			EQU		0F0h	; Blinking reverse video
MONO_REVERSE_DARK_BLINK		EQU		0F8h	; (blinking dark green on green)


; Cursor position macro for DX register
%define CURSOR_XY(x, y)	( (x) | ((y)<<8) )

; Cursor shapes
CURSOR_NORMAL				EQU		0607h		; Two line cursor near or at the bottom of cell
CURSOR_HIDDEN				EQU		2000h


; Display modes
CGA_TEXT_MODE_BW40			EQU		0		; Applications should use...
CGA_TEXT_MODE_CO40			EQU		1
CGA_TEXT_MODE_BW80			EQU		2		; ..black, white and bright white attributes only
CGA_TEXT_MODE_CO80			EQU		3
MDA_TEXT_MODE				EQU		7		; Real monochrome attributes available


; Display segments
COLOR_TEXT_SEGMENT			EQU		0B800h	; Text modes 0...3 (CGA+)
MONO_TEXT_SEGMENT			EQU		0B000h	; Text mode 7 (MDA, Hercules)


; Control characters for teletype output
NULL						EQU		00h
SOH							EQU		01h		; Start of heading
STX							EQU		02h		; Start of text
BELL						EQU		07h		; Bell
BS							EQU		08h		; Backspace
TAB							EQU		09h		; Horizontal TAB
LF							EQU		0Ah		; Line feed (newline)
CR							EQU		0Dh		; Carriage return
ESC							EQU		1Bh		; Escape

; Non ASCII characters (code page 437)
DOUBLE_TOP_RIGHT_CORNER						EQU		187
DOUBLE_TOP_LEFT_CORNER						EQU		201
DOUBLE_BOTTOM_RIGHT_CORNER					EQU		188
DOUBLE_BOTTOM_LEFT_CORNER					EQU		200
DOUBLE_VERTICAL								EQU		186
DOUBLE_HORIZONTAL							EQU		205
DOUBLE_VERTICAL_TO_RIGHT_SINGLE				EQU		199
DOUBLE_VERTICAL_TO_LEFT_SINGLE				EQU		182
DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL	EQU		181
DOUBLE_RIGHT_HORIZONTAL_TO_SINGLE_VERTICAL	EQU		198
SINGLE_HORIZONTAL							EQU		196
SINGLE_LEFT_HORIZONTAL_TO_VERTICAL			EQU		180
SINGLE_RIGHT_HORIZONTAL_TO_VERTICAL			EQU		195
ANGLE_QUOTE_LEFT							EQU		174
ANGLE_QUOTE_RIGHT							EQU		175
BLOCK_MOSTLY_BACKGROUND						EQU		176
BLOCK_EVEN_BACKGROUND_AND_FOREGROUND		EQU		177
BLOCK_MOSTLY_FOREGROUND						EQU		178
BLOCK_FULL_FOREGROUND						EQU		219


; Background character for clearing screen
%ifndef SCREEN_BACKGROUND_CHARACTER
	%define	SCREEN_BACKGROUND_CHARACTER		BLOCK_MOSTLY_BACKGROUND
%endif
%ifndef SCREEN_BACKGROUND_ATTRIBUTE
	%define	SCREEN_BACKGROUND_ATTRIBUTE		MONO_NORMAL
%endif

%endif ; DISPLAY_INC
