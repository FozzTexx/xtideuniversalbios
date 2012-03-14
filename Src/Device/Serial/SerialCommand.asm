; Project name	:	XTIDE Universal BIOS
; Description	:	Serial Device Command functions.

; Section containing code
SECTION .text

%define SERIALSERVER_AH_ALREADY_HAS_COMMAND_BYTE
%define SERIALSERVER_NO_ZERO_SECTOR_COUNTS		

;--------------------------------------------------------------------
; SerialCommand_OutputWithParameters
;	Parameters:
;		BH:		Non-zero if 48-bit addressing used
;               (ignored at present as 48-bit addressing is not supported)
;		BL:		IDE Status Register bit to poll after command
;               (ignored at present, since there is no IDE status register to poll)
;		ES:SI:	Ptr to buffer (for data transfer commands)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors (for transfer commands)
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, (ES:SI for data transfer commands)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialCommand_OutputWithParameters:

		mov		ah,SerialServer_Command_Read

		mov		al,[bp+IDEPACK.bCommand]

		cmp		al,20h			; Read Sectors IDE command
		jz		.readOrWrite
		inc		ah				; now SerialServer_Protocol_Write
		cmp		al,30h			; Write Sectors IDE command
		jz		.readOrWrite

;  all other commands return success
;  including function 0ech which should return drive information, this is handled with the identify functions
;
		xor		ah,ah			;  also clears carry
		ret

.readOrWrite:
		mov		[bp+IDEPACK.bFeatures],ah		; store protocol command
				
		mov		dx, [di+DPT_SERIAL.wSerialPortAndBaud]

ALIGN JUMP_ALIGN
SerialCommand_FallThroughToSerialServer_SendReceive:

%include "SerialServer.asm"

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS		
	%if SerialCommand_FallThroughToSerialServer_SendReceive <> SerialServer_SendReceive
		%error "SerialServer_SendReceive must be the first routine at the top of SerialServer.asm in the Assembly_Library"
	%endif
%endif

ALIGN JUMP_ALIGN		
SerialCommand_ReturnError:		
		stc
		ret		

;--------------------------------------------------------------------
; SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;		DS:		Segment to RAMVARS
;		ES:SI:	Ptr to buffer to receive 512-byte IDE Information
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BL, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH:
;
; To improve boot time, we do our best to avoid looking for slave serial drives when we already know the results
; from the looking for a master.  This is particularly true when doing a COM port scan, as we will end up running
; through all the COM ports and baud rates a second time.
;
; But drive detection isn't the only case - we also need to get the right drive when called on int13h/25h.
;
; The decision tree:
;
;    Master:
;		   wSerialPortAndBaud Non-Zero:           -> Continue with wSerialPortAndBaud (1)
;		   wSerialPortAndBaud Zero:
;		       previous serial drive not found:   -> Scan (2)
;		       previous serial drive found:       -> Continue with previous serial drive info (3)
;
;    Slave:
;		   wSerialPortAndBaud Non-Zero:
;		   	   previous serial drive not found:   -> Error - Not Found (4)
;			   previous serial drive found:       -> Continue with wSerialPackedAndBaud (5)
;          wSerialPortAndBaud Zero:
;		   	   previous serial drive not found:	  -> Error - Not Found (4)
;			   previous serial drive found:       -> Continue with previous serial drive info (6)
;
; (1) This was a port/baud that was explicitly set with the configurator.  In the drive detection case, as this
;     is the Master, we are checking out a new controller, and so don't care if we already have a serial drive.
;     And as with the int13h/25h case, we just go off and get the needed information using the user's setting.
; (2) We are using the special .ideVarsSerialAuto structure.  During drive detection, we would only be here
;     if we hadn't already seen a serial drive (since we only scan if no explicit drives are set),
;     so we go off to scan.
; (3) We are using the special .ideVarsSerialAuto structure.  We won't get here during drive detection, but
;     we might get here on an int13h/25h call.  If we have scanned COM drives, they are the ONLY serial drives
;     in use, and so we use the values from the previously seen serial drive DPT.
; (4) No master has been found yet, therefore no slave should be found.  Avoiding the slave reduces boot time,
;     especially in the full COM port scan case.  Note that this is different from the hardware IDE, where we
;     will scan for a slave even if a master is not present.  Note that if ANY master had been previously found,
;     we will do the slave scan, which isn't harmful, it just wastes time.  But the most common case (by a wide
;     margin) will be just one serial controller.
; (5) A COM port scan for a master had been previously completed, and a drive was found.  In a multiple serial
;     controller scenario being called with int13h/25h, we need to use the value in bSerialPackedPortAndBaud
;     to make sure we get the proper drive.
; (6) A COM port scan for a master had been previously completed, and a drive was found.  We would only get here
;     if no serial drive was explicitly set by the user in the configurator or that drive had not been found.
;     Instead of performing the full COM port scan for the slave, use the port/baud value stored during the
;     master scan.
;
		mov		dx,[cs:bp+IDEVARS.wSerialPortAndBaud]
		xor		ax,ax
		
		push	si
		call	FindDPT_ToDSDIforSerialDevice
		pop		si
%ifdef MODULE_SERIAL_FLOPPY
		jnc		.founddpt
;
; If not found above with FindDPT_ToDSDIforSerialDevice, DI will point to the DPT after the last hard disk DPT
; So, if there was a previously found floppy disk, DI will point to that DPT and we use that value for the slave.
;
		cmp		byte [RAMVARS.xlateVars+XLATEVARS.bFlopCntAndFirst], 0
		jz		.notfounddpt
.founddpt:
%else
		jc		.notfounddpt
%endif
		mov		ax, [di+DPT_SERIAL.wSerialPortAndBaud]
.notfounddpt:

		test	bh, FLG_DRVNHEAD_DRV
		jz		.master

		test	ax,ax			; Take care of the case that is different between master and slave.
		jz		SerialCommand_ReturnError

; fall-through
.master:
		test	dx,dx
		jnz		.identifyDeviceInDX

		xchg	dx, ax			;  move ax to dx (move previously found serial drive to dx, could be zero)

.identifyDeviceInDX:

ALIGN JUMP_ALIGN
SerialCommand_FallThroughToSerialServerScan_ScanForServer:		
		
%include "SerialServerScan.asm"

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS				
	%if SerialCommand_FallThroughToSerialServerScan_ScanForServer <> SerialServerScan_ScanForServer
		%error "SerialServerScan_ScanForServer must be the first routine at the top of SerialServerScan.asm in the Assembly_Library"
	%endif
%endif


