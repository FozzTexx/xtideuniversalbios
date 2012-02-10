; Project name	:	XTIDE Universal BIOS
; Description	:	Sets IDE Device specific parameters to DPT.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeDPT_Finalize
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
IdeDPT_Finalize:
	; Fall to .StoreBlockMode

;--------------------------------------------------------------------
; .StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StoreBlockMode:
	mov		al, 1
	mov		ah, [es:si+ATA1.bBlckSize]		; Max block size in sectors
	mov		[di+DPT_ATA.wSetAndMaxBlock], ax
	; Fall to IdeDPT_StoreReversedAddressLinesFlagIfNecessary

;--------------------------------------------------------------------
; IdeDPT_StoreReversedAddressLinesFlagIfNecessary
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
IdeDPT_StoreReversedAddressLinesFlagIfNecessary:
	cmp		BYTE [cs:bp+IDEVARS.bDevice], DEVICE_XTIDE_WITH_REVERSED_A3_AND_A0
	jne		SHORT .EndDPT
	or		BYTE [di+DPT.bFlagsHigh], FLGH_DPT_REVERSED_A0_AND_A3

.EndDPT:
	ret
