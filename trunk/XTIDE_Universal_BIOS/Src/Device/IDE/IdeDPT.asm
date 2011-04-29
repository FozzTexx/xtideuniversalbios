; Project name	:	XTIDE Universal BIOS
; Description	:	Sets IDE Device specific parameters to DPT.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeDPT_Finalize
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
IdeDPT_Finalize:
	; Fall to .StoreBlockMode

;--------------------------------------------------------------------
; .StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreBlockMode:
	mov		al, 1
	mov		ah, [es:si+ATA1.bBlckSize]		; Max block size in sectors
	mov		[di+DPT_ATA.wSetAndMaxBlock], ax
	; Fall to .EndDPT


.EndDPT:
	ret
