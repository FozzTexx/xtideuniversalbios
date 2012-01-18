; Project name	:	XTIDE Universal BIOS
; Description	:	Serial Device Command functions.

; Section containing code
SECTION .text

;--------------- UART Equates -----------------------------
;
; Serial Programming References:
;    http://en.wikibooks.org/wiki/Serial_Programming
;

SerialCommand_UART_base							EQU		0
SerialCommand_UART_transmitByte					EQU		0
SerialCommand_UART_receiveByte					EQU		0
SerialCommand_UART_divisorLow					EQU		0
; Values for UART_divisorLow:
; 60h = 1200, 30h = 2400, 18h = 4800, 0ch = 9600, 6 = 19200, 3 = 38400, 2 = 57600, 1 = 115200

SerialCommand_UART_divisorLow_startingBaud		EQU   030h
; We support 4 baud rates, starting here going higher and skipping every other baud rate
; Starting with 30h, that means 30h (1200 baud), 0ch (9600 baud), 3 (38400 baud), and 1 (115200 baud)
; Note: hardware baud multipliers (2x, 4x) will impact the final baud rate and are not known at this level

SerialCommand_UART_interruptEnable				EQU		1
SerialCommand_UART_divisorHigh					EQU		1
; UART_divisorHigh is zero for all speeds including and above 1200 baud

SerialCommand_UART_interruptIdent				EQU		2
SerialCommand_UART_FIFOControl					EQU		2

SerialCommand_UART_lineControl					EQU		3

SerialCommand_UART_modemControl					EQU		4

SerialCommand_UART_lineStatus					EQU		5

SerialCommand_UART_modemStatus					EQU		6

SerialCommand_UART_scratch						EQU		7

SerialCommand_Protocol_Write					EQU		3
SerialCommand_Protocol_Read						EQU		2
SerialCommand_Protocol_Inquire					EQU		0
SerialCommand_Protocol_Header					EQU		0a0h

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
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, (ES:SI for data transfer commands)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialCommand_OutputWithParameters:

		mov		ah,(SerialCommand_Protocol_Header | SerialCommand_Protocol_Read)

		mov		al,[bp+IDEPACK.bCommand]

		cmp		al,20h			; Read Sectors IDE command
		jz		.readOrWrite
		inc		ah				; now SerialCommand_Protocol_Write
		cmp		al,30h			; Write Sectors IDE command
		jz		.readOrWrite

;  all other commands return success
;  including function 0ech which should return drive information, this is handled with the identify functions
		xor		ah,ah			;  also clears carry
		ret

.readOrWrite:
		mov		[bp+IDEPACK.bFeatures],ah		; store protocol command

		mov		dl, byte [di+DPT.bSerialPortAndBaud]

; fall-through

;--------------------------------------------------------------------
; SerialCommand_OutputWithParameters_DeviceInDL
;	Parameters:
;       AH:		Protocol Command
;       DL:		Packed I/O port and baud rate
;		ES:SI:	Ptr to buffer (for data transfer commands)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, (ES:SI for data transfer commands)
;--------------------------------------------------------------------
SerialCommand_OutputWithParameters_DeviceInDL:

		push	si
		push	di
		push	bp
		push	es

;
; Unpack I/O port and baud from DPT
;		Port to DX more or less for the remainder of the routine
;		Baud in CH until UART initialization is complete
;
		mov		dh, ((DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT & 0f00h) >> (8+1))
		shl		dx, 1		; port offset already x4, needs one more shift to be x8
		mov		cl, dl

		and		cl, (DEVICE_SERIAL_PACKEDPORTANDBAUD_BAUDMASK << 1)
		mov		ch, SerialCommand_UART_divisorLow_startingBaud
		shr		ch, cl
		adc		ch, 0

		and		dl, ((DEVICE_SERIAL_PACKEDPORTANDBAUD_PORTMASK << 1) & 0ffh)
		add		dx, byte (DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT & 0ffh)

		mov		al,[bp+IDEPACK.bSectorCount]

;
; Command byte and sector count live at the top of the stack, pop/push are used to access
;
		push	ax

;		cld		; Shouldn't be needed. DF has already been cleared (line 24, Int13h.asm)

;----------------------------------------------------------------------
;
; Initialize UART
;
; We do this each time since DOS (at boot) or another program may have
; decided to reprogram the UART
;
		mov		bl,dl			; setup BL with proper values for read/write loops (BH comes later)
		
		mov		al,83h
		add		dl,SerialCommand_UART_lineControl
		out		dx,al

		mov		al,ch
		mov		dl,bl			; divisor low
		out		dx,al

		xor		ax,ax
		inc		dx				; divisor high
		push	dx
		out		dx,al

		mov		al,047h
		inc		dx				;  fifo
		out		dx,al

		mov		al,03h
		inc		dx				;  linecontrol
		out		dx,al

		mov		al,0bh
		inc		dx				;  modemcontrol
		out		dx,al

		inc		dx				;  linestatus (no output now, just setting up BH for later use)
		mov		bh,dl

		pop		dx				; base, interrupts disabled
		xor		ax,ax
		out		dx,al

;----------------------------------------------------------------------
;
; Send Command
;
; Sends first six bytes of IDEREGS_AND_INTPACK as the command
;
		push	es				; save off real buffer location
		push	si

		mov		si,bp			; point to IDEREGS for command dispatch;
		push	ss
		pop		es

		mov		di,0ffffh		; initialize checksum for write
		mov		bp,di

		mov		cx,4			; writing 3 words (plus 1)

		cli						; interrupts off... 

		call	SerialCommand_WriteProtocol.entry

		pop		di				; restore real buffer location (note change from SI to DI)
								; Buffer is primarily referenced through ES:DI throughout, since
								; we need to store (read sector) faster than we read (write sector)
		pop		es

.nextSectorNormalize:			

		call	Registers_NormalizeESDI	
		
		pop		ax				; load command byte (done before call to .nextSector on subsequent iterations)
		push	ax

;
; Top of the read/write loop, one iteration per sector
;
.nextSector:
		mov		si,0ffffh		; initialize checksum for read or write
		mov		bp,si

		mov		cx,0101h		; writing 256 words (plus 1)

		shr		ah,1			; command byte, are we doing a write?
		jnc		.readEntry

		xchg	si,di
		call	SerialCommand_WriteProtocol.entry
		xchg	si,di

		inc		cx				; CX = 1 now (0 out of WriteProtocol)
		jmp		.readEntry

;----------------------------------------------------------------------
;
; Timeout
;
; To save code space, we use the contents of DL to decide which byte in the word to return for reading.
;
.readTimeout:
		push	ax				; not only does this push preserve AX (which we need), but it also
								; means the stack has the same number of bytes on it as when we are 
								; sending a packet, important for error cleanup and exit
		mov		ah,1
		call	SerialCommand_WaitAndPoll_Read
		pop		ax
		test	dl,1
		jz		.readByte1Ready
		jmp		.readByte2Ready		

;----------------------------------------------------------------------------
;
; Read Block (without interrupts, used when there is a FIFO, high speed)
;
; NOTE: This loop is very time sensitive.  Literally, another instruction
; cannot be inserted into this loop without us falling behind at high
; speed (460.8K baud) on a 4.77Mhz 8088, making it hard to receive
; a full 512 byte block.
;
.readLoop:
		stosw					; store word in caller's data buffer

		add		bp, ax			; update Fletcher's checksum
		adc		bp, 0
		add		si, bp
		adc		si, 0

.readEntry:		
		mov		dl,bh
		in		al,dx
		shr		al,1			; data ready (byte 1)?
		mov		dl,bl			; get ready to read data
		jnc		.readTimeout	; nope not ready, update timeouts

;
; Entry point after initial timeout.  We enter here so that the checksum word
; is not stored (and is left in AX after the loop is complete).
;
.readByte1Ready:
		in		al, dx			; read data byte 1

		mov		ah, al			; store byte in ah for now

;
; note the placement of this reset of dl to bh, and that it is
; before the return, which is assymetric with where this is done
; above for byte 1.  The value of dl is used by the timeout routine
; to know which byte to return to (.read_byte1_ready or
; .read_byte2_ready)
;
		mov		dl,bh

		in		al,dx
		shr		al,1			; data ready (byte 2)?
		jnc		.readTimeout
.readByte2Ready:
		mov		dl,bl
		in		al, dx			; read data byte 2

		xchg	al, ah			; ah was holding byte 1, reverse byte order

		loop	.readLoop

		sti						; interrupts back on ASAP, between packets

;
; Compare checksums
;
		xchg	ax,bp
		xor		ah,al
		mov		cx,si
		xor		cl,ch
		mov		al,cl
		cmp		ax,bp
		jnz		SerialCommand_OutputWithParameters_Error

;----------------------------------------------------------------------
;
; Clear read buffer
;
; In case there are extra characters or an error in the FIFO, clear it out.
; In theory the initialization of the UART registers above should have
; taken care of this, but I have seen cases where this is not true.
;
.clearBuffer:
		mov		dl,bh
		in		al,dx
		mov		dl,bl
		test	al,08fh
		jz		.clearBufferComplete
		shr		al,1
		in		al,dx
		jc		.clearBuffer	; note CF from shr above
		jmp		SerialCommand_OutputWithParameters_Error

.clearBufferComplete:

		pop		ax				; sector count and command byte
		dec		al				; decrememnt sector count
		push	ax				; save
		jz		SerialCommand_OutputWithParameters_ReturnCodeInALCF    ; CF clear from .clearBuffer test above

		cli						; interrupts back off for ACK byte to host
								; (host could start sending data immediately)
		out		dx,al			; ACK with next sector number

;
; Normalize buffer pointer for next go round, if needed
;
		test	di,di
		jns		short .nextSector
		jmp		short .nextSectorNormalize

;---------------------------------------------------------------------------
;
; Cleanup, error reporting, and exit
;

;
; Used in situations where a call is underway, such as with SerialCommand_WaitAndPoll
;
ALIGN JUMP_ALIGN
SerialCommand_OutputWithParameters_ErrorAndPop4Words:
		add		sp,8

ALIGN JUMP_ALIGN
SerialCommand_OutputWithParameters_Error:
		stc
		mov		al,1

ALIGN JUMP_ALIGN
SerialCommand_OutputWithParameters_ReturnCodeInALCF:
		sti
		mov		ah,al

		pop		bp				;  recover ax (command and count) from stack, throw away

		pop		es
		pop		bp
		pop		di
		pop		si

		ret

;--------------------------------------------------------------------
; SerialCommand_WriteProtocol
;
; NOTE: As with its read counterpart, this loop is very time sensitive.  
; Although it will still function, adding additional instructions will 
; impact the write througput, especially on slower machines.  
;
;	Parameters:
;		ES:SI:	Ptr to buffer
;		CX:		Words to write, plus 1
;		BP/DI:	Initialized for Checksum (-1 in each)
;		DH:		I/O Port high byte
;		BX:		LineStatus Register address (BH) and Receive/Transmit Register address (BL)
;	Returns:
;		BP/DI:	Checksum for written bytes, compared against ACK from server in .readLoop
;		CX:     Zero
;		DL:		Receive/Transmit Register address
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialCommand_WriteProtocol:
.writeLoop:
		es lodsw				; fetch next word

		out		dx,al			; output first byte

		add		bp,ax			; update checksum
		adc		bp,0
		add		di,bp
		adc		di,0

		mov		dl,bh			; transmit buffer empty?
		in		al,dx
		test	al,20h
		jz		.writeTimeout2	; nope, use our polling routine

.writeByte2Ready:
		mov		dl,bl
		mov		al,ah			; output second byte
		out		dx,al

.entry:
		mov		dl,bh			; transmit buffer empty?
		in		al,dx
		test	al,20h
		mov		dl,bl
		jz		.writeTimeout1	; nope, use our polling routine

.writeByte1Ready:
		loop	.writeLoop

		mov		ax,di			; fold Fletcher's checksum and output
		xor		al,ah
		out		dx,al			; byte 1

		call	SerialCommand_WaitAndPoll_Write

		mov		ax,bp
		xor		al,ah
		out		dx,al			; byte 2

		ret

.writeTimeout2:
		mov		dl,ah			; need to preserve AH, but don't need DL (will be reset upon return)
		call	SerialCommand_WaitAndPoll_Write
		mov		ah,dl
		jmp		.writeByte2Ready
		
.writeTimeout1:
		mov		ax,.writeByte1Ready
		push	ax				; return address for ret at end of SC_writeTimeout2
;;; fall-through

;--------------------------------------------------------------------
; SerialCommand_WaitAndPoll
;
;	Parameters:
;		AH:		UART_LineStatus bit to test (20h for write, or 1h for read)
;               One entry point fills in AH with 20h for write
;		DX:		Port address (OK if already incremented to UART_lineStatus)
;       BX:    
;       Stack:	2 words on the stack below the command/count word
;	Returns:
;       Returns when desired UART_LineStatus bit is cleared
;       Jumps directly to error exit if timeout elapses (and cleans up stack)
;	Corrupts registers:
;       AX
;--------------------------------------------------------------------

SerialCommand_WaitAndPoll_SoftDelayTicks   EQU   20

ALIGN JUMP_ALIGN
SerialCommand_WaitAndPoll_Write:
		mov		ah,20h
;;; fall-through

ALIGN JUMP_ALIGN
SerialCommand_WaitAndPoll_Read:
		push	cx
		push	dx

;
; We first poll in a tight loop, interrupts off, for the next character to come in/be sent
;
		xor		cx,cx
.readTimeoutLoop:
		mov		dl,bh				
		in		al,dx
		test	al,ah
		jnz		.readTimeoutComplete
		loop	.readTimeoutLoop

;
; If that loop completes, then we assume there is a long delay involved, turn interrupts back on
; and wait for a given number of timer ticks to pass.
;
		sti
		mov		cl,SerialCommand_WaitAndPoll_SoftDelayTicks
		call	Timer_InitializeTimeoutWithTicksInCL
.WaitAndPoll:
		call	Timer_SetCFifTimeout
		jc		SerialCommand_OutputWithParameters_ErrorAndPop4Words
		in		al,dx
		test	al,ah
		jz		.WaitAndPoll
		cli

.readTimeoutComplete:
		pop		dx
		pop		cx
		ret

;--------------------------------------------------------------------
; SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;		DS:		Segment to RAMVARS
;		ES:SI:	Ptr to buffer to receive 512-byte IDE Information
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		AH:		INT 13h Error Code
;               NOTE: Not set (or checked) during drive detection 
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BL, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH:
;
; To improve boot time, we do our best to avoid looking for slave serial drives when we already know the results 
; from the looking for a master.  This is particuarly true when doing a COM port scan, as we will end up running
; through all the COM ports and baud rates a second time.  
;
; But drive detection isn't the only case - we also need to get the right drive when called on int13h/25h.  
;
; The decision tree:
;
;    Master:
;		   bSerialPackedPortAndBaud Non-Zero:   -> Continue with bSerialPackedAndBaud (1)
;		   bSerialPackedPortAndBaud Zero: 
;		   			      bLastSerial Zero:     -> Scan (2)
;					      bLastSerial Non-Zero: -> Continue with bLastSerial (3)
;			  				        
;    Slave:
;		   bSerialPackedPortAndBaud Non-Zero: 
;		   			      bLastSerial Zero:     -> Error - Not Found (4)
;					      bLastSerial Non-Zero: -> Continue with bSerialPackedAndBaud (5)
;          bSerialPackedPortAndBaud Zero:     
;		   			      bLastSerial Zero:     -> Error - Not Found (4)
;					      bLastSerial Non-Zero: -> Continue with bLastSerial (6)
;
; (1) This was a port/baud that was explicilty set with the configurator.  In the drive detection case, as this 
;     is the Master, we are checking out a new controller, and so don't care about the value of bLastSerial.  
;     And as with the int13h/25h case, we just go off and get the needed information using the user's setting.
; (2) We are using the special .ideVarsSerialAuto strucutre.  During drive detection, we would only be here
;     if bLastSerial is zero (since we only scan if no explicit drives are set), so we go off to scan.
; (3) We are using the special .ideVarsSerialAuto strucutre.  We won't get here during drive detection, but
;     we might get here on an int13h/25h call.  If we have scanned COM drives, they are the ONLY serial drives
;     in use, and so bLastSerial will reflect the port/baud setting for the scanned COM drives.
; (4) No master has been found yet, therefore no slave should be found.  Avoiding the slave reduces boot time, 
;     especially in the full COM port scan case.  Note that this is different from the hardware IDE, where we
;     will scan for a slave even if a master is not present.  Note that if ANY master had been previously found,
;     we will do the slave scan, which isn't harmful, it just wates time.  But the most common case (by a wide
;     margin) will be just one serial controller.
; (5) A COM port scan for a master had been previously completed, and a drive was found.  In a multiple serial
;     controller scenario being called with int13h/25h, we need to use the value in bSerialPackedPortAndBaud 
;     to make sure we get the proper drive.
; (6) A COM port scan for a master had been previously completed, and a drive was found.  We would only get here 
;     if no serial drive was explicitly set by the user in the configurator or that drive had not been found.  
;     Instead of performing the full COM port scan for the slave, use the port/baud value stored during the 
;     master scan.
;		
		mov		dl,[cs:bp+IDEVARS.bSerialPackedPortAndBaud]		
		mov		al,	byte [RAMVARS.xlateVars+XLATEVARS.bLastSerial]
				
		test	bh, FLG_DRVNHEAD_DRV
		jz		.master

		test	al,al			; Take care of the case that is different between master and slave.  
		jz		.error			; Because we do this here, the jz after the "or" below will not be taken

; fall-through
.master:		
		test	dl,dl
		jnz		.identifyDeviceInDL

		or		dl,al			; Move bLast into position in dl, as well as test for zero
		jz		.scanSerial
		
; fall-through
.identifyDeviceInDL:	

		push	bp				; setup fake IDEREGS_AND_INTPACK

		push	dx

		mov		cl,1			; 1 sector to move
		push	cx

		mov		bl,0a0h			; protocol command to ah and onto stack with bh
		mov		ah,bl

		push	bx

		mov		bp,sp
		call	SerialCommand_OutputWithParameters_DeviceInDL

		pop		bx

		pop		cx
		pop		dx

		pop		bp
; 
; place packed port/baud in RAMVARS, read by FinalizeDPT and DetectDrives
;
; Note that this will be set during an int13h/25h call as well.  Which is OK since it is only used (at the
; top of this routine) for drives found during a COM scan, and we only COM scan if there were no other 
; COM drives found.  So we will only reaffirm the port/baud for the one COM port/baud that has a drive.
; 
		jc		.notFound											; only store bLastSerial if success
		mov		byte [RAMVARS.xlateVars+XLATEVARS.bLastSerial], dl

.notFound:		
		ret

;----------------------------------------------------------------------
;
; SerialCommand_AutoSerial
;
; When the SerialAuto IDEVARS entry is used, scans the COM ports on the machine for a possible serial connection.
;

.scanPortAddresses: db	DEVICE_SERIAL_COM7 >> 2
					db	DEVICE_SERIAL_COM6 >> 2
					db	DEVICE_SERIAL_COM5 >> 2
					db	DEVICE_SERIAL_COM4 >> 2
					db	DEVICE_SERIAL_COM3 >> 2
					db	DEVICE_SERIAL_COM2 >> 2
					db	DEVICE_SERIAL_COM1 >> 2
					db	0

ALIGN JUMP_ALIGN
.scanSerial:
		mov		di,.scanPortAddresses-1

.nextPort:
		inc		di				; load next port address
		mov		dl,[cs:di]

		mov		dh,0			; shift from one byte to two
		eSHL_IM	dx, 2
		jz		.error

;
; Test for COM port presence, write to and read from registers
;
		push	dx
		add		dl,SerialCommand_UART_lineControl
		mov		al, 09ah
		out		dx, al
		in		al, dx
		pop		dx
		cmp		al, 09ah
		jnz		.nextPort

		mov		al, 0ch
		out		dx, al
		in		al, dx
		cmp		al, 0ch
		jnz		.nextPort

;
; Pack into dl, baud rate starts at 0
;
		add		dx,-(DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT)
		shr		dx,1			; dh is zero at this point, and will be sent to the server,
								; so we know this is an auto detect

		jmp		.testFirstBaud

;
; Walk through 4 possible baud rates
;
.nextBaud:
		inc		dx
		test	dl,3
		jz		.nextPort

.testFirstBaud:
		call	.identifyDeviceInDL
		jc		.nextBaud

		ret

.error:	
		stc
		; mov		ah,1		; setting the error code is unnecessary as this path can only be taken during
								; drive detection, and drive detection works off CF and does not check AH
		ret


