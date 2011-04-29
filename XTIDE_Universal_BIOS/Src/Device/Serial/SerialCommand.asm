; Project name	:	XTIDE Universal BIOS
; Description	:	Serial Device Command functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;		DS:		Segment to RAMVARS
;		ES:SI:	Ptr to buffer to receive 512-byte IDE Information
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BL, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH:


;--------------------------------------------------------------------
; SerialCommand_OutputWithParameters
;	Parameters:
;		BH:		Non-zero if 48-bit addressing used
;		BL:		IDE Status Register bit to poll after command
;		ES:SI:	Ptr to buffer (for data transfer commands)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, (ES:SI for data transfer commands)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialCommand_OutputWithParameters:


