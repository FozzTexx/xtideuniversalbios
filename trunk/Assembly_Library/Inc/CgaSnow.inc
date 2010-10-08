; File name		:	CgaSnow.inc
; Project name	:	AssemblyLibrary
; Created date	:	8.10.2010
; Last update	:	8.10.2010
; Author		:	Tomi Tilli
; Description	:	Macros for preventing CGA snow.
%ifndef CGASNOW_INC
%define CGASNOW_INC

;--------------------------------------------------------------------
; WAIT_RETRACE_IF_NECESSARY_THEN
;	Parameters:
;		%1:		Instruction that accessed CGA memory
;		AL:		Character to output
;		AH:		Attribute to output (stosw only)
;		DS:		BDA segment (zero)
;		ES:SI:	Ptr to video memory where to read from (if %1 reads)
;		ES:DI:	Ptr to video memory where to output (if %1 writes)
;	Returns:
;		SI, DI:	Updated according to instruction
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
%macro WAIT_RETRACE_IF_NECESSARY_THEN 1
%ifdef ELIMINATE_CGA_SNOW
	%ifidn %1, stosb
		call	CgaSnow_StosbWithoutCgaSnow
	%elifidn %1, stosw
		call	CgaSnow_StoswWithoutCgaSnow
	%elifidn %1, scasb
		call	CgaSnow_ScasbWithoutCgaSnow
	%elifidn %1, rep movsb
		call	CgaSnow_RepMovsbWithoutCgaSnow
	%else
		%error	"Invalid instruction passed to WAIT_RETRACE_IF_NECESSARY_THEN"
	%endif
%else	; No CGA snow prevention
	%ifidn %1, rep movsb
		eSEG_STR rep, es, movsb
	%else
		%1	; Single instruction
	%endif
%endif
%endmacro


;--------------------------------------------------------------------
; WAIT_UNTIL_SAFE_CGA_WRITE
;	Parameters:
;		DX:		CGA Status Register Address (3DAh)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
%macro WAIT_UNTIL_SAFE_CGA_WRITE 0
%%WaitUntilNotInRetrace:
	in		al, dx
	shr		al, 1	; 1 = Bit 0: A 1 indicates that regen-buffer memory access can be
					; made without interfering with the display. (H or V retrace)
	jc		SHORT %%WaitUntilNotInRetrace
%%WaitUntilNextRetraceStarts:
	in		al, dx
	shr		al, 1
	jnc		SHORT %%WaitUntilNextRetraceStarts
%endmacro


%endif ; CGASNOW_INC
