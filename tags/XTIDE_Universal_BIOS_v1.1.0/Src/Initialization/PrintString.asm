; File name		:	PrintString.asm
; Project name	:	IDE BIOS
; Created date	:	19.3.2010
; Last update	:	31.3.2010
; Author		:	Tomi Tilli
; Description	:	Functions for printing strings used in this IDE BIOS.


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints string with formatting parameters.
; Do not call PrintString_JumpToFormat!!! Jump there only!
; 
; PrintString_JumpToFormat
;	Parameters:
;		DH:		Number of bytes pushed to stack
;		CS:SI:	Ptr to string to format
;		Stack:	Parameters for formatting placeholders.
;				Parameter for first placeholder must be pushed last
;				(to top of stack).
;				High word must be pushed first for 32-bit parameters.
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintString_JumpToFormat:
	mov		cx, ds				; Backup DS
	push	cs					; Push string segment...
	pop		ds					; ...and pop it to DS
	mov		dl, ' '				; Min length character
	call	Print_Format
	mov		ds, cx				; Restore DS
	eMOVZX	ax, dh				; Bytes in stack
	add		sp, ax				; Clean stack
	ret


;--------------------------------------------------------------------
; Prints STOP terminated string from wanted segment.
; 
; PrintString_FromCS
; PrintString_FromES
; PrintString_FromDS
;	Parameters:
;		SI:		Offset to string to print
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintString_FromCS:
	push	ds
	push	cs					; Push string segment...
	pop		ds					; ...and pop it to DS
	call	PrintString_FromDS
	pop		ds
	ret

ALIGN JUMP_ALIGN
PrintString_FromES:
	push	ds
	push	es					; Push string segment...
	pop		ds					; ...and pop it to DS
	call	PrintString_FromDS
	pop		ds
	ret

ALIGN JUMP_ALIGN
PrintString_FromDS:
	mov		dx, si				; DS:DX now points to string
	PRINT_STR_LEN
	ret
