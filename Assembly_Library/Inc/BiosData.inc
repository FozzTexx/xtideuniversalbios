; Project name	:	XTIDE Universal BIOS
; Description	:	Equates for BIOS Data Area.
%ifndef BIOSDATA_INC
%define BIOSDATA_INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BIOS DATA AREA VARIABLES ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; BIOS Data Area (related to floppy drives and hard disks)
struc BDA
					resb	400h	; 40:0h, Start of BDA
	.wCOM1			resb	2		; 0:400h, Serial I/O Address, Port 1
	.wCOM2			resb	2		; 0:402h, Serial I/O Address, Port 2
	.wCOM3			resb	2		; 0:404h, Serial I/O Address, Port 3
	.wCOM4			resb	2		; 0:406h, Serial I/O Address, Port 4
	.wLPT1			resb	2		; 0:408h, Parallel I/O Address, Port 1
	.wLPT2			resb	2		; 0:40Ah, Parallel I/O Address, Port 2
	.wLPT3			resb	2		; 0:40Ch, Parallel I/O Address, Port 3
	.wLPT4:							; 0:40Eh, Parallel I/O Address, Port 4 (PC/XT)
	.wSegEBDA		resb	2		; 0:40Eh, Extended BIOS Data Area segment (AT+)

	.wEquipment		resb	2		; 0:410h, Equipment Word
	.bTest			resb	1		; 0:412h, Manufacturing test
	.wBaseMem		resb	2		; 0:413h, Base Memory Size in kB
	.wAdptrMem:						; 0:415h, Adapter Memory Size (PC/XT)
	.wError			resb	2		; 0:415h, Error Codes (AT+)
	.bKBFlgs1		resb	1		; 0:417h, Keyboard, Shift Flags, Set 1
	.bKBFlgs2		resb	1		; 0:418h, Keyboard, Shift Flags, Set 2
	.bKBNumpad		resb	1		; 0:419h, Keyboard, ALT+Numpad work area
	.wKBHead		resb	2		; 0:41Ah, Keyboard, Head of buffer pointer
	.wKBTail		resb	2		; 0:41Ch, Keyboard, Tail of buffer pointer
	.rgwKBBuff		resb	32		; 0:41Eh, Keyboard, 16-word buffer

	.bFDRecal		resb	1		; 0:43Eh, Diskette, Recalibrate status
	.bFDMotor		resb	1		; 0:43Fh, Diskette, Motor status

	.bFDMotTime		resb	1		; 0:440h, Diskette, Motor timeout counter
	.bFDRetST		resb	1		; 0:441h, Diskette, Controller status return code
	.rgbFDStatus	resb	7		; 0:442h, Diskette, Diskette and Disk Controller status bytes
	.bVidMode		resb	1		; 0:449h, Video, Mode
	.wVidColumns	resb	2		; 0:44Ah, Video, Number of columns
	.wVidBpP		resb	2		; 0:44Ch, Video, Total number of bytes per page
	.wVidPageOff	resb	2		; 0:44Eh, Video, Current page offset

	.rgwVidCurPos	resb	16		; 0:450h, Video, Cursor position, pages 0...7

	.wVidCurShape	resb	2		; 0:460h, Video, Cursor shape
	.bVidPageIdx	resb	1		; 0:462h, Video, Active display page
	.wVidPort		resb	2		; 0:463h, Video, I/O Port number base
	.bVidModeReg	resb	1		; 0:465h, Video, Internal mode register
	.bVidPalette	resb	1		; 0:466h, Video, Color palette
	.wCasTimeCnt:					; 0:467h, Cassette, Time count at data edge (PC)
	.wGenOff		resb	2		; 0:467h, General use offset (XT+)
	.wCasCRC:						; 0:469h, Cassette, CRC register (PC)
	.wGenSeg		resb	2		; 0:469h, General use segment (XT+)
	.bCasLast:						; 0:46Bh, Cassette, Last value read
	.bLastIRQ		resb	1		; 0:46Bh, Last interrupt that occurred (XT+)
	.dwTimerTicks	resb	4		; 0:46Ch, Timer ticks count

	.bTimer24h		resb	1		; 0:470h, Timer ticks rollover flag
	.bKBCtrlBrk		resb	1		; 0:471h, Keyboard, Ctrl+Break flag
	.wBoot			resb	2		; 0:472h, Warm boot flag
	.bHDLastSt		resb	1		; 0:474h, Hard Disk, Status of Last Operation (XT+)
	.bHDCount		resb	1		; 0:475h, Hard Disk, Number of HDs Attached (XT+)
	.bHDCtrl		resb	1		; 0:476h, Hard Disk, Control Byte (temp, XT+)
	.bHDPortOff		resb	1		; 0:477h, Hard Disk, Port Offset (XT)
	.bLPT1Timeout	resb	1		; 0:478h, Parallel Printer 1, Timeout (XT+)
	.bLPT2Timeout	resb	1		; 0:479h, Parallel Printer 2, Timeout (XT+)
	.bLPT3Timeout	resb	1		; 0:47Ah, Parallel Printer 3, Timeout (XT+)
	.bLPT4Timeout	resb	1		; 0:47Bh, Parallel Printer 4, Timeout (XT+)
	.bCOM1Timeout	resb	1		; 0:47Ch, Serial 1, Timeout (XT+)
	.bCOM2Timeout	resb	1		; 0:47Dh, Serial 2, Timeout (XT+)
	.bCOM3Timeout	resb	1		; 0:47Eh, Serial 3, Timeout (XT+)
	.bCOM4Timeout	resb	1		; 0:47Fh, Serial 4, Timeout (XT+)

	.wKBPtrStart	resb	2		; 0:480h, Keyboard, Pointer to start of buffer (XT+)
	.wKBPtrEnd		resb	2		; 0:482h, Keyboard, Pointer to end of buffer (XT+)
	.bVidRows		resb	1		; 0:484h, Video, Number of rows minus one (EGA+)
	.wVidPpC		resb	2		; 0:485h, Video, Pixels per character (EGA+)
	.bVidOptns		resb	1		; 0:487h, Video, Options (EGA+)
	.bVidSwitches	resb	1		; 0:488h, Video, Switches (EGA+)
	.bVidSave1		resb	1		; 0:489h, Video, Save area 1 (VGA+)
	.bVidSave2		resb	1		; 0:48Ah, Video, Save area 2 (VGA+)
	.bFDCfgData		resb	1		; 0:48Bh, Diskette, Configuration data (AT+)
	.bHDStatus		resb	1		; 0:48Ch, Hard Disk, Status Register (AT+)
	.bHDError		resb	1		; 0:48Dh, Hard Disk, Error Register (AT+)
	.bHDTaskFlg		resb	1		; 0:48Eh, Hard Disk, Task Complete Flag (AT+)
	.bFDCtrlInfo	resb	1		; 0:48Fh, Diskette, Controller information (AT+)

	.bFDMedia0		resb	1		; 0:490h, Diskette 0, Media state (AT+)
	.bFDMedia1		resb	1		; 0:491h, Diskette 1, Media state (AT+)
	.bFDOpStart0	resb	1		; 0:492h, Diskette 0, Operational starting state (AT+)
	.bFDOpStart1	resb	1		; 0:493h, Diskette 1, Operational starting state (AT+)
	.bFDCurCyl0		resb	1		; 0:494h, Diskette 0, Current cylinder (AT+)
	.bFDCurCyl1		resb	1		; 0:495h, Diskette 1, Current cylinder (AT+)
	.bKBFlgs3		resb	1		; 0:496h, Keyboard, Status flags 3 (AT+)
	.bKBFlgs4		resb	1		; 0:497h, Keyboard, Status flags 4 (AT+)
	.dwWaitPtr		resb	4		; 0:498h, User's wait flag pointer (AT+)
	.dwWaitCnt		resb	4		; 0:49Ch, User's wait count (AT+)

	.bWaitFlg		resb	1		; 0:4A0h, Wait flag (AT+)
	.rgbLAN			resb	7		; 0:4A1h, Local Area Network (AT+)
	.dwVidPtr		resb	4		; 0:4A8h, Video, Parameter Control Block Pointer (EGA+)
					resb	22h		; Reserved from 0:4ACh...0:4CDh

	.dwDays			resb	4		; 0:4CEh, Clock, Days since 1980 (some BIOSes, AT+)
					resb	2Eh		; Reserved from 0:4D2h...0:4FFh

	.bPrntScrn		resb	1		; 0:500, Print screen status
endstruc

; BDA struct with only Hard Disk related locations
struc HDBDA
					resb	474h
	.bHDLastSt		resb	1		; 0:474h, Status of Last Operation (XT+)
	.bHDCount		resb	1		; 0:475h, Number of HDs Attached (XT+)
	.bHDCtrl		resb	1		; 0:476h, Control Byte (temp, XT+)
	.bHDPortOff		resb	1		; 0:477h, Port Offset (XT)
					resb	15h
	.bHDStatus:						; 0:48Ch, Status Register (AT+)
	.bHDError:						; 0:48Dh, Error Register (AT+)
	.wHDStAndErr	resb	2
	.bHDTaskFlg		resb	1		; 0:48Eh, Task Complete Flag (AT+)
endstruc


; Warm Boot Flags for BDA.wBoot
BOOT_FLAG_COLD			EQU	0
BOOT_FLAG_WARM			EQU	1234h	; Same effect as CTRL + ALT + DEL, skips memory tests
BOOT_FLAG_PRESERVE_RAM	EQU	4321h	; No mem test, leave memory unchanged (AT+)


%endif ; BIOSDATA_INC
