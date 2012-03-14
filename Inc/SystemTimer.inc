; Project name	:	Assembly Library
; Description	:	System Timer (8254) relates equates and macros.
%ifndef SYSTEMTIMER_INC
%define SYSTEMTIMER_INC

; Timer/Counter to program
TIMER_0									EQU	(0<<6)
TIMER_1									EQU	(1<<6)
TIMER_2									EQU	(2<<6)

; Counter commands
LATCH									EQU	(0<<4)	; Counter Latch Command (latches the count for reading)
READ_OR_WRITE_LSB_ONLY					EQU	(1<<4)	; MSB is always zero
READ_OR_WRITE_MSB_ONLY					EQU	(2<<4)	; LSB is always zero
READ_OR_WRITE_LSB_THEN_MSB				EQU	(3<<4)

; Timer modes
MODE_0_SINGLE_TIMEOUT					EQU	(0<<1)	; Interrupt on Terminal Count
MODE_1_ONE_SHOT							EQU	(1<<1)	; Hardware Retriggerable One-Shot
MODE_2_RATE_GENERATOR					EQU	(2<<1)
MODE_3_SQUARE_WAVE_MODE					EQU	(3<<1)
MODE_4_SOFTWARE_TRIGGERED_STROBE		EQU	(4<<1)
MODE_5_HARDWARE_RETRIGGERABLE_STROBE	EQU	(5<<1)

; Binary / BCD Mode
BINARY_COUNTER							EQU	0
BCD_COUNTER								EQU	1


; Ports
COUNT_REGISTER_0						EQU	40h		; Timer 0 Count Register (System Timer Ticks)
COUNT_REGISTER_1						EQU	41h		; Timer 1 Count Register (DRAM Refresh)
COUNT_REGISTER_2						EQU	42h		; Timer 2 Count Register (General Use)
CONTROL_WORD_REGISTER_out				EQU	43h

; Timer 2 is connected to PC Speaker that can be controller from port 61h.
SPEAKER_CONTROL_REGISTER				EQU	61h
FLG_TIMER_2_OUTPUT_in					EQU	(1<<5)	; AT+ only
FLG_SPEAKER_DATA_ENABLED				EQU	(1<<1)
FLG_SPEAKER_GATE_TIMER_2_ON				EQU	(1<<0)


; The duration of one tick
TIMER_CYCLE_TIME						EQU	838		; nanosecs




;--------------------------------------------------------------------
; OUTPUT_COUNTER_COMMAND_TO
;	Parameters:
;		%1:		TIMER_0, TIMER_1 or TIMER_2
;		%2:		Command to counter
;		%3:		Timer mode
;		%4:		BINARY_COUNTER or BCD_COUNTER
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
%macro OUTPUT_COUNTER_COMMAND_TO 4
	mov		al, %1 | %2 | %3 | %4
	out		CONTROL_WORD_REGISTER_out, al
%endmacro


;--------------------------------------------------------------------
; WRITE_COUNT_FROM_AL_TO
; WRITE_COUNT_FROM_AX_TO
;	Parameters:
;		%1:		TIMER_0, TIMER_1 or TIMER_2
;		AX:		Count to write to timer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL (WRITE_COUNT_FROM_AX_TO only)
;--------------------------------------------------------------------
%macro WRITE_COUNT_FROM_AL_TO 1
	%ifidni %1, TIMER_0
		out		COUNT_REGISTER_0, al
	%elifidni %1, TIMER_1
		out		COUNT_REGISTER_1, al
	%elifidni %1, TIMER_2
		out		COUNT_REGISTER_2, al
	%else
		%error "Invalid timer name passed to WRITE_COUNT_FROM_AL_TO"
	%endif
%endmacro

%macro WRITE_COUNT_FROM_AX_TO 1
	%ifidni %1, TIMER_0
		out		COUNT_REGISTER_0, al
		mov		al, ah
		out		COUNT_REGISTER_0, al
	%elifidni %1, TIMER_1
		out		COUNT_REGISTER_1, al
		mov		al, ah
		out		COUNT_REGISTER_1, al
	%elifidni %1, TIMER_2
		out		COUNT_REGISTER_2, al
		mov		al, ah
		out		COUNT_REGISTER_2, al
	%else
		%error "Invalid timer name passed to WRITE_COUNT_FROM_AX_TO"
	%endif
%endmacro


;--------------------------------------------------------------------
; READ_COUNT_TO_AL_FROM
; READ_COUNT_TO_AX_FROM
;	Parameters:
;		%1:		TIMER_0, TIMER_1 or TIMER_2
;	Returns:
;		AL/AX:	Counter value
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro READ_COUNT_TO_AL_FROM 1
	%ifidni %1, TIMER_0
		in		al, COUNT_REGISTER_0
	%elifidni %1, TIMER_1
		in		al, COUNT_REGISTER_1
	%elifidni %1, TIMER_2
		in		al, COUNT_REGISTER_2
	%else
		%error "Invalid timer name passed to READ_COUNT_TO_AL_FROM"
	%endif
%endmacro

%macro READ_COUNT_TO_AX_FROM 1
	%ifidni %1, TIMER_0
		in		al, COUNT_REGISTER_0
		mov		ah, al
		in		al, COUNT_REGISTER_0
	%elifidni %1, TIMER_1
		in		al, COUNT_REGISTER_1
		mov		ah, al
		in		al, COUNT_REGISTER_1
	%elifidni %1, TIMER_2
		in		al, COUNT_REGISTER_2
		mov		ah, al
		in		al, COUNT_REGISTER_2
	%else
		%error "Invalid timer name passed to READ_COUNT_TO_AX_FROM"
	%endif
		xchg	al, ah
%endmacro


;--------------------------------------------------------------------
; START_PRECISE_EVENT_TIMER
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
%macro START_PRECISE_EVENT_TIMER 0
	in		al, SPEAKER_CONTROL_REGISTER
	or		al, FLG_SPEAKER_GATE_TIMER_2_ON
	out		SPEAKER_CONTROL_REGISTER, al
%endmacro


;--------------------------------------------------------------------
; STOP_PRECISE_EVENT_TIMER
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
%macro STOP_PRECISE_EVENT_TIMER 0
	in		al, SPEAKER_CONTROL_REGISTER
	and		al, ~(FLG_SPEAKER_DATA_ENABLED | FLG_SPEAKER_GATE_TIMER_2_ON)
	out		SPEAKER_CONTROL_REGISTER, al
%endmacro


%endif ; SYSTEMTIMER_INC
