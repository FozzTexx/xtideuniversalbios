; Project name	:	XTIDE Universal BIOS
; Description	:	Sets Serial Device specific parameters to DPT.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; SerialDPT_Finalize
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Set, indicates that this is a floppy disk
;               Clear, indicates that this is a hard disk
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
SerialDPT_Finalize:
		mov		ax, [es:si+ATA6.wSerialPortAndBaud]
		mov		[di+DPT_SERIAL.wSerialPortAndBaud], ax

;
; Note that this section is not under %ifdef MODULE_SERIAL_FLOPPY.  It is important to 
; detect floppy disks presented by the server and not treat them like hard disks, even
; if the floppy support is disabled.
;
		mov		al, [es:si+ATA6.wSerialFloppyFlagAndType]
		or		al, FLGH_DPT_SERIAL_DEVICE
		or		byte [di+DPT.bFlagsHigh], al

		test	al, FLGH_DPT_SERIAL_FLOPPY           ; clears CF
		jz		.notfloppy
		stc		
.notfloppy:		
		
		ret

