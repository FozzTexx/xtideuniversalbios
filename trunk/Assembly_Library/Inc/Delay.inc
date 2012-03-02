; Project name	:	Assembly Library
; Description	:	Delay macros.
%ifndef DELAY_INC
%define DELAY_INC

;--------------------------------------------------------------------
; Clears prefetch queue by jumping to next instruction.
; This delays much more than nop instruction of fast systems.
;
; JMP_DELAY
;	Parameters
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro JMP_DELAY 0
	jmp		SHORT %%NextInstruction
%%NextInstruction:
%endmacro


;--------------------------------------------------------------------
; Mimimun delays (without fetching) with some CPU architectures:
;	8088/8086:	17 cycles for jump + 5 cycles for last comparison
;	286:		10 cycles for jump + 4 cycles for last comparison
;	386:		13 cycles for jump + ? cycles for last comparison
;	486:		 7 cycles for jump + 6 cycles for last comparison
;
; LOOP instruction uses two bytes so aligned fetching will require:
;   8088:		8 cycles (two BYTE reads)
;   8086:		4 cycles (one WORD read)
;   286:		2 cycles + wait states (usually 1)
;   386:		?
;	486:		Fetched only once to internal cache
;
; DELAY_WITH_LOOP_INSTRUCTION_NA	; No JUMP_ALIGN
; DELAY_WITH_LOOP_INSTRUCTION
;	Parameters
;		CX:		Loop iterations (0 is maximum delay with 65536 iterations)
;	Returns:
;		CX:		Zero
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro DELAY_WITH_LOOP_INSTRUCTION_NA 0
%%StartOfLoop:
	loop	%%StartOfLoop
%endmacro

%macro DELAY_WITH_LOOP_INSTRUCTION 0
ALIGN JUMP_ALIGN
%%StartOfLoop:
	loop	%%StartOfLoop
%endmacro


%endif ; DELAY_INC
