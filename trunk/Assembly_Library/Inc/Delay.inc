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
; DELAY_WITH_LOOP_INSTRUCTION
;	Parameters
;		CX:		Loop iterations (0 is maximum delay with 65536 iterations)
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
%macro DELAY_WITH_LOOP_INSTRUCTION 0
%%StartOfLoop:
	loop	%%StartOfLoop
%endmacro


%endif ; DELAY_INC
