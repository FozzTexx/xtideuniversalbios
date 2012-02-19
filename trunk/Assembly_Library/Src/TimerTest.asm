; Project name	:	Assembly Library
; Description	:	Tests for Assembly Library.

; Include .inc files
%define INCLUDE_DISPLAY_LIBRARY
%define INCLUDE_TIME_LIBRARY
%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!


; Section containing code
SECTION .text

; Program first instruction.
ORG	100h						; Code starts at offset 100h (DOS .COM)
Start:
	jmp		TimerTest_Start

; Include library sources
%include "AssemblyLibrary.asm"


;--------------------------------------------------------------------
; Program start
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
TimerTest_Start:	
	CALL_DISPLAY_LIBRARY InitializeDisplayContext

	call	SystemTimer_IntializePreciseEventTimer

	START_PRECISE_EVENT_TIMER
	mov		ax, MICROSECONDS_TO_WAIT
	call	Delay_MicrosecondsFromAX
	STOP_PRECISE_EVENT_TIMER

	call	SystemTimer_ReadNanosecsToDXAXfromPreciseEventTimer
	call	PrintNanosecsFromDXAX

	; Exit to DOS
	mov 	ax, 4C00h			; Exit to DOS
	int 	21h


ALIGN JUMP_ALIGN
PrintNanosecsFromDXAX:
	mov		cx, 1000
	div		cx					; AX = us waited
	
	mov		bp, sp
	ePUSH_T	cx, MICROSECONDS_TO_WAIT
	push	ax
	mov		si, g_szMicrosecsWaited
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret



; Section containing initialized data
SECTION .data

MICROSECONDS_TO_WAIT		EQU		7000

g_szMicrosecsWaited:
	db	"Was supposed to wait %u us but actually waited %u us.",LF,CR,NULL
g_szDashForZero:		db		"- ",NULL



; Section containing uninitialized data
SECTION .bss
