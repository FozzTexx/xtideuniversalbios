; Project name	:	Assembly Library
; Description	:	Tests for Assembly Library.

; Include .inc files
%define INCLUDE_DISPLAY_LIBRARY
%define INCLUDE_TIME_LIBRARY
%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!


; Section containing code
SECTION .text

; Program first instruction.
CPU 486
ORG	100h						; Code starts at offset 100h (DOS .COM)
Start:
	jmp		BusMeasurements_Start

; Include library sources
%include "AssemblyLibrary.asm"

%macro MOV_TIMING_LOOP 1
	xor		bx, bx					; Offset for memory transfers
	mov		dx, OFFSET_TO_NEXT_WORD	; Must be at least 32 (Pentium Cache Line size)
	wbinvd							; Flush and invalidate internal cache
	cli								; Disable interrupts
	START_PRECISE_EVENT_TIMER
ALIGN 8
%%ReadNextWord:
	mov		ax, %1					; 2 bytes
	add		bx, dx					; 2 bytes
	jnc		SHORT %%ReadNextWord	; 2 bytes
	STOP_PRECISE_EVENT_TIMER
	sti
%endmacro


;--------------------------------------------------------------------
; Program start
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BusMeasurements_Start:
	CALL_DISPLAY_LIBRARY InitializeDisplayContext
	xor		ax, ax
	mov		ds, ax

	call	MeasureRegAndMemMovDurationDifferenceToAX
	call	GetBusCycleTimeToAXfromRegAndMemMovDurationDifferenceInAX
	call	GetBusClockRateFromCycleTimeInAX
	mov		si, g_szBusMeasurements
	call	PrintBusMeasurements

	call	AssumeVlbCycleTimeToAXfromBusCycleTimeInCX
	call	GetBusClockRateFromCycleTimeInAX
	mov		si, g_szVlbAssumption
	call	PrintBusMeasurements

	; Exit to DOS
	mov 	ax, 4C00h			; Exit to DOS
	int 	21h



;--------------------------------------------------------------------
; MeasureRegAndMemMovDurationDifferenceToAX
;	Parameters:
;		DS:		Segment for memory read tests
;	Returns:
;		AX:		Difference in register and memory access durations
;				(Precise Event Timer Ticks)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
MeasureRegAndMemMovDurationDifferenceToAX:
	call	SystemTimer_IntializePreciseEventTimer

	MOV_TIMING_LOOP	bx
	call	SystemTimer_GetPreciseEventTimerTicksToAX
	xchg	cx, ax		; Duration now in CX

	MOV_TIMING_LOOP [bx]
	call	SystemTimer_GetPreciseEventTimerTicksToAX
	sub		ax, cx		; AX = Difference in durations
	sub		ax, cx
	ret


;--------------------------------------------------------------------
; We must divide the duration by 4 since the timing loop loads
; whole cache line (4 times the bus width) instead of single BYTE.
;
; GetBusCycleTimeToAXfromRegAndMemMovDurationDifferenceInAX
;	Parameters:
;		AX:		Difference in register and memory access durations
;				(Precise Event Timer Ticks)	
;	Returns:
;		AX:		Duration for single BYTE in nanosecs
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
GetBusCycleTimeToAXfromRegAndMemMovDurationDifferenceInAX:
	mov		dx, TIMER_CYCLE_TIME
	mul		dx			; DX:AX = Duration in nanosecs
	mov		cx, (65536 / OFFSET_TO_NEXT_WORD) * 4
	div		cx			; AX = Duration for single BYTE in nanosecs
	ret


;--------------------------------------------------------------------
; GetBusClockRateFromCycleTimeInAX
;	Parameters:
;		AX:		Bus Cycle Time in nanosecs
;	Returns:
;		CX:		Bus Cycle Time in nanosecs
;		DX:		Bus Clock Rate (MHz)
;		AX:		Clock Rate tenths
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
GetBusClockRateFromCycleTimeInAX:
	xchg	cx, ax
	xor		dx, dx
	mov		ax, 1000
	div		cl			; AL = MHz, AH = Remainder
	xchg	al, dl		; DX = Bus Clock Rate, AL = 0
	aad					; AX = 10 * AH (+AL)
	div		cl
	xor		ah, ah		; AX = Tenths
	ret


;--------------------------------------------------------------------
; AssumeVlbCycleTimeToAXfromBusCycleTimeInCX
;	Parameters:
;		CX:		Bus Cycle Time in nanosecs
;	Returns:
;		AX:		Assumed VLB Cycle Time in nanosecs
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AssumeVlbCycleTimeToAXfromBusCycleTimeInCX:
	mov		ax, cx
	cmp		al, 24		; 25 = 40 MHz
	jb		SHORT .AssumePentiumSoDivideBy2
	ret
.AssumePentiumSoDivideBy2:
	shr		ax, 1
	ret


;--------------------------------------------------------------------
; PrintBusMeasurements
;	Parameters:
;		CX:		Bus Cycle Time in nanosecs
;		DX:		Bus Clock Rate (MHz)
;		AX:		Clock Rate tenths
;		SI:		Offset to string to format
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, BP
;--------------------------------------------------------------------
PrintBusMeasurements:
	mov		bp, sp
	push	cx
	push	dx
	push	ax
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	ret



; Section containing initialized data
SECTION .data

OFFSET_TO_NEXT_WORD		EQU	32	; Must be at least 32 (Pentium Cache Line size)

g_szBusMeasurements:
	db	"Detected bus cycle time of %u ns (%u.%u MHz) ",LF,CR,NULL
g_szVlbAssumption:
	db	"Assuming VLB (if exists) cycle time of %u ns (%u.%u MHz) ",LF,CR,NULL
g_szDashForZero:		db		"- ",NULL



; Section containing uninitialized data
SECTION .bss
