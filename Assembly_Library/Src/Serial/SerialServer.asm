; Project name	:	Assembly Library
; Description	:	Serial Server Support

%include "SerialServer.inc"
		
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; SerialServer_SendReceive:		
;	Parameters:
;       DX:		Packed I/O port and baud rate
;		ES:SI:	Ptr to buffer (for data transfer commands)
;		SS:BP:	Ptr to SerialServer_Command structure
;	Returns:
;		AH:		INT 13h Error Code
;       CX:     Number of 512-byte blocks transferred
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
SerialServer_SendReceive:		
		
		push	si
		push	di
		push	bp

;
; Unpack I/O port and baud from DPT
;		Port to DX for the remainder of the routine (+/- different register offsets)
;		Baud in CH until UART initialization is complete
;
		mov		ch,dh
		xor		dh,dh
		eSHL_IM	dx, 2			; shift from one byte to two

		mov		al,[bp+SerialServer_Command.bSectorCount]
		mov		ah,[bp+SerialServer_Command.bCommand]
;
; Command byte and sector count live at the top of the stack, pop/push are used to access
;
		push	ax				; save sector count for return value
		push	ax				; working copy on the top of the stack

		cld

;----------------------------------------------------------------------
;
; Initialize UART
;
; We do this each time since DOS (at boot) or another program may have
; decided to reprogram the UART
;
		mov		bl,dl			; setup BL with proper values for read/write loops (BH comes later)

		mov		al,83h
		add		dl,Serial_UART_lineControl
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

		call	SerialServer_WriteProtocol.entry

		pop		di				; restore real buffer location (note change from SI to DI)
								; Buffer is primarily referenced through ES:DI throughout, since
								; we need to store (read sector) faster than we read (write sector)
		pop		es

		pop		ax				; load command byte (done before call to .nextSector on subsequent iterations)
		push	ax

		test	al,al			; if no sectors to be transferred, wait for the ACK checksum on the command
		jz		.zeroSectors

;
; Top of the read/write loop, one iteration per sector
;
.nextSector:
		mov		si,0ffffh		; initialize checksum for read or write
		mov		bp,si

		mov		cx,0101h		; writing 256 words (plus 1)

		shr		ah,1			; command byte, are we doing a write?
		jnc		.readEntry

		xchg	si,di			; swap pointer and checksum, will be re-swap'ed in WriteProtocol
		call	SerialServer_WriteProtocol.entry

.zeroSectors:
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
		call	SerialServer_WaitAndPoll_Read
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
		jnz		SerialServer_OutputWithParameters_Error

		pop		ax				; sector count and command byte
		dec		al				; decrement sector count
		push	ax				; save
		jz		SerialServer_OutputWithParameters_ReturnCodeInAL

		cli						; interrupts back off for ACK byte to host
								; (host could start sending data immediately)
		out		dx,al			; ACK with next sector number

		jmp		short .nextSector

;---------------------------------------------------------------------------
;
; Cleanup, error reporting, and exit
;

;
; Used in situations where a call is underway, such as with SerialServer_WaitAndPoll
;
ALIGN JUMP_ALIGN
SerialServer_OutputWithParameters_ErrorAndPop4Words:
		add		sp,8
;;; fall-through

ALIGN JUMP_ALIGN
SerialServer_OutputWithParameters_Error:
;----------------------------------------------------------------------
;
; Clear read buffer
;
; In case there are extra characters or an error in the FIFO, clear it out.
; In theory the initialization of the UART registers above should have
; taken care of this, but I have seen cases where this is not true.
;
		xor		cx,cx					; timeout this clearing routine, in case the UART isn't there
.clearBuffer:
		mov		dl,bh
		in		al,dx
		mov		dl,bl
		test	al,08fh
		jz		.clearBufferComplete
		test	al,1
		in		al,dx
		loopnz	.clearBuffer			; note ZF from test above

.clearBufferComplete:
		mov		al, 3			;  error return code and CF (low order bit)

ALIGN JUMP_ALIGN
SerialServer_OutputWithParameters_ReturnCodeInAL:
%if 0
		sti						;  all paths here will already have interrupts turned back on
%endif
		mov		ah, al			;  for success, AL will already be zero
		
		pop		bx				;  recover "ax" (command and count) from stack
		pop		cx				;  recover saved sector count
		mov		ch, 0
		sub		cl, bl			; subtract off the number of sectors that remained

		pop		bp
		pop		di
		pop		si

		shr		ah, 1			; shift down return code and CF

		ret

;--------------------------------------------------------------------
; SerialServer_WriteProtocol
;
; NOTE: As with its read counterpart, this loop is very time sensitive.
; Although it will still function, adding additional instructions will
; impact the write throughput, especially on slower machines.
;
;	Parameters:
;		ES:SI:	Ptr to buffer
;		CX:		Words to write, plus 1
;		BP/DI:	Initialized for Checksum (-1 in each)
;		DH:		I/O Port high byte
;		BX:		LineStatus Register address (BH) and Receive/Transmit Register address (BL)
;	Returns:
;		BP/SI:	Checksum for written bytes, compared against ACK from server in .readLoop
;		CX:     Zero
;		DL:		Receive/Transmit Register address
;		ES:DI:  Ptr to buffer
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SerialServer_WriteProtocol:
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

		call	SerialServer_WaitAndPoll_Write

		mov		ax,bp
		xor		al,ah
		out		dx,al			; byte 2

		xchg	si,di			; preserve checksum word in si, move pointer back to di

		ret

.writeTimeout2:
		mov		dl,ah			; need to preserve AH, but don't need DL (will be reset upon return)
		call	SerialServer_WaitAndPoll_Write
		mov		ah,dl
		jmp		.writeByte2Ready

.writeTimeout1:
%ifndef USE_186
		mov		ax,.writeByte1Ready
		push	ax				; return address for ret at end of SC_writeTimeout2
%else
		push	.writeByte1Ready
%endif
;;; fall-through

;--------------------------------------------------------------------
; SerialServer_WaitAndPoll
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

SerialServer_WaitAndPoll_SoftDelayTicks   EQU   20

ALIGN JUMP_ALIGN
SerialServer_WaitAndPoll_Write:
		mov		ah,20h
;;; fall-through

ALIGN JUMP_ALIGN
SerialServer_WaitAndPoll_Read:
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
		mov		cl,SerialServer_WaitAndPoll_SoftDelayTicks
%ifndef SERIALSERVER_TIMER_LOCATION
		call	Timer_InitializeTimeoutWithTicksInCL
%else
		push	ax
		push	bx
		mov		ax,SerialServer_WaitAndPoll_SoftDelayTicks
		mov		bx,SERIALSERVER_TIMER_LOCATION
		call	TimerTicks_InitializeTimeoutFromAX
		pop		bx
		pop		ax
%endif
		
.WaitAndPoll:
%ifndef SERIALSERVER_TIMER_LOCATION
		call	Timer_SetCFifTimeout
%else
		push	ax
		push	bx
		mov		bx,SERIALSERVER_TIMER_LOCATION
		call	TimerTicks_GetTimeoutTicksLeftToAXfromDSBX
		pop		bx
		pop		ax
%endif		
		jc		SerialServer_OutputWithParameters_ErrorAndPop4Words
		in		al,dx
		test	al,ah
		jz		.WaitAndPoll
		cli

.readTimeoutComplete:
		pop		dx
		pop		cx
		ret


