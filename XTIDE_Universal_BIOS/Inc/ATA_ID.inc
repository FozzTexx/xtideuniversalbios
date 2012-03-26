; Project name	:	XTIDE Universal BIOS
; Description	:	ATA Identify Drive information.
%ifndef ATA_ID_INC
%define ATA_ID_INC

; PIO Minimum Cycle Times (t0)
; Timings for Advanced modes 3 and 4 can be read from ATA info WORDs 67 and 68
PIO_0_MIN_CYCLE_TIME_NS		EQU		600
PIO_1_MIN_CYCLE_TIME_NS		EQU		383
PIO_2_MIN_CYCLE_TIME_NS		EQU		240
PIO_3_MIN_CYCLE_TIME_NS		EQU		180
PIO_4_MIN_CYCLE_TIME_NS		EQU		120

; PIO Minimum Address Valid Times (t1)
PIO_0_MIN_ADDRESS_VALID_NS	EQU		70
PIO_1_MIN_ADDRESS_VALID_NS	EQU		50
PIO_2_MIN_ADDRESS_VALID_NS	EQU		30
PIO_3_MIN_ADDRESS_VALID_NS	EQU		30
PIO_4_MIN_ADDRESS_VALID_NS	EQU		25

; PIO Minimum Active Times (t2)
PIO_0_MIN_ACTIVE_TIME_NS	EQU		165
PIO_1_MIN_ACTIVE_TIME_NS	EQU		125
PIO_2_MIN_ACTIVE_TIME_NS	EQU		100
PIO_3_MIN_ACTIVE_TIME_NS	EQU		80
PIO_4_MIN_ACTIVE_TIME_NS	EQU		70

; PIO Minimum Recovery Times or Inactive Times (t2i) can be calculated
; from Minimum Cycle Time (t0) - Minimum Active Time (t2) - Address Valid Time (t1). 
; I'm not sure about this calculation so correct me if I'm wrong!
; Recovery time should be calculated at run time since Cycle Time t0 can be
; read from ATA information (ATA2+) but most drives just report the
; Min Cycle Times listed above.



; ATA-1 Drive Information struct
; F = Fixed value
; V = Variable value
; R = Reserved word
; X = Vendor specific word
struc ATA1
	.wGenCfg	resw 1	; 0F, General configuration bit-significant information
	.wCylCnt	resw 1	; 1F, Number of cylinders
				resw 1	; 2R
	.wHeadCnt	resw 1	; 3F, Number of heads
	.wBpTrck	resw 1	; 4F, Number of unformatted bytes per track
	.wBpSect	resw 1	; 5F, Number of unformatted bytes per sector
	.wSPT		resw 1	; 6F, Number of sectors per track 
				resw 3	; 7...9X
	.strSerial	resb 20	; 10...19F, Serial number (20 ASCII characters, 0000h=not specified)
	.wBuffType	resw 1	; 20F, Buffer type
	.wBuffSize	resw 1	; 21F, Buffer size in 512 byte increments (0000h=not specified)
	.wEccCnt	resw 1	; 22F, # of ECC bytes avail on read/write long cmds (0000h=not spec'd)
	.strFirmW	resb 8	; 23...26F, Firmware revision (8 ASCII characters, 0000h=not specified)
	.strModel	resb 40	; 27...46F, Model number (40 ASCII characters, 0000h=not specified)
	.bBlckSize	resb 1	; 47[0-7]F, Maximum number of sectors that can be transferred
						;          per interrupt on read and write multiple commands
						;		   (00h=Read/write multiple commands not implemented)
				resb 1	; 47[8-15]X
	.wDWIO		resw 1	; 48F, Can perform doubleword I/O (boolean)
	.wCaps		resw 1	; 49FRX, Capabilities
				resw 1	; 50R
				resb 1	; 51[0-7]X
	.bPioMode	resb 1	; 51[8-15]F, PIO data transfer cycle timing mode (0, 1 or 2)
				resb 1	; 52[0-7]X
	.bDMATiming	resb 1	; 52[8-15]F, DMA data transfer cycle timing mode
	.wFields	resw 1	; 53FVR, Field (next words) validity bits

	; Words 54-58 are valid only if bit0 is set in .wFields
	.wCurCyls	resw 1	; 54V, Number of current cylinders
	.wCurHeads	resw 1	; 55V, Number of current heads
	.wCurSPT	resw 1	; 56V, Number of current sectors per track
	.dwCurSCnt	resd 1	; 57...58V, Current capacity in sectors

	; Words 59-63 are always valid
	.bBlockSel	resb 1	; 59[0-7]V, Current setting for number of sectors that
						;           can be transferred per interrupt on R/W multiple command
	.bBlockFlgs	resb 1	; 59[8-15]VR, bit 0 set if Multiple sector setting is valid
	.dwLBACnt	resd 1	; 60...61F, Total number of user addressable sectors (LBA mode only)
	.bSDMASupp	resb 1	; 62[0-7]F, Single word DMA transfer modes supported
	.bSDMAAct	resb 1	; 62[8-15]V, Single word DMA transfer mode active
	.bMDMASupp	resb 1	; 63[0-7]F, Multiword DMA transfer modes supported
	.bMDMAAct	resb 1	; 63[8-15]V, Multiword DMA transfer mode active
endstruc

A1_MODEL_NUMBER_LENGTH	EQU	40		; 40 ASCII characters

; ATA-1 Word 0, General configuration
A1_wGenCfg_NONMAG		EQU	(1<<15)	; Reserved for non-magnetic drives
A1_wGenCfg_FGAPREQ		EQU	(1<<14)	; Format speed tolerance gap required
A1_wGenCfg_TRCKOFF		EQU	(1<<13)	; Track offset option available
A1_wGenCfg_DATAOFF		EQU	(1<<12)	; Data strobe offset option available
A1_wGenCfg_ROTTOL		EQU	(1<<11)	; Rotational speed tolerance is > 0,5%
A1_wGenCfg_XFERFAST		EQU (1<<10)	; Disk transfer rate > 10 Mbs
A1_wGenCfg_XFERMED		EQU	(1<<9)	; Disk transfer rate > 5Mbs but <= 10Mbs
A1_wGenCfg_XFERSLOW		EQU (1<<8)	; Disk transfer rate <= 5Mbs
A1_wGenCfg_REMOVABLE	EQU	(1<<7)	; Removable cartridge drive
A1_wGenCfg_FIXED		EQU	(1<<6)	; Fixed drive
A1_wGenCfg_MOTCTRL		EQU	(1<<5)	; Spindle motor control option implemented
A1_wGenCfg_HEADSLOW		EQU	(1<<4)	; Head switch time > 15 usec
A1_wGenCfg_NOTMFM		EQU	(1<<3)	; Not MFM encoded
A1_wGenCfg_SOFTSECT		EQU	(1<<2)	; Soft sectored
A1_wGenCfg_HARDSECT		EQU	(1<<1)	; Hard sectored

; ATA-1 Word 49, Capabilities
A1_wCaps_LBA			EQU	(1<<9)	; LBA supported
A1_wCaps_DMA			EQU	(1<<8)	; DMA supported

; ATA-1 Word 53, Fields
A1_wFields_54to58		EQU	(1<<0)	; The fields reported in words 54-58 are valid

; ATA-1 Word 59 high byte, Block mode flags
A1_bBlockFlgs_VALID		EQU	(1<<0)	; Multiple sector setting (bBlockSel) is valid


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ATA-2 Drive Information struct
; F = Fixed value
; V = Variable value
; R = Reserved word
; X = Vendor specific word
struc ATA2
	.wGenCfg	resw 1	; 0F, General configuration bit-significant information
	.wCylCnt	resw 1	; 1F, Number of logical cylinders
				resw 1	; 2R
	.wHeadCnt	resw 1	; 3F, Number of logical heads
				resw 1	; 4X
				resw 1	; 5X
	.wSPT		resw 1	; 6F, Number of logical sectors per track 
				resw 3	; 7...9X
	.strSerial	resb 20	; 10...19F, Serial number (20 ASCII characters, 0000h=not specified)
				resw 1	; 20X
				resw 1	; 21X
	.wEccCnt	resw 1	; 22F, # of ECC bytes avail on read/write long cmds (0000h=not spec'd)
	.strFirmW	resb 8	; 23...26F, Firmware revision (8 ASCII characters, 0000h=not specified)
	.strModel	resb 40	; 27...46F, Model number (40 ASCII characters, 0000h=not specified)
	.bBlckSize	resb 1	; 47[0-7]F, Maximum number of sectors that can be transferred
						;          per interrupt on read and write multiple commands
						;		   (00h=Read/write multiple commands not implemented)
				resb 1	; 47[8-15]X
				resw 1	; 48R
	.wCaps		resw 1	; 49FRX, Capabilities
				resw 1	; 50R
				resb 1	; 51[0-7]X
	.bPIOTiming	resb 1	; 51[8-15]F, PIO data transfer cycle timing mode
				resb 1	; 52[0-7]X
	.bDMATiming	resb 1	; 52[8-15]F, DMA data transfer cycle timing mode
	.wFields	resw 1	; 53FVR, Field (next words) validity bits

	; Words 54-58 are valid only if bit0 is set in .wFields
	.wCurCyls	resw 1	; 54V, Number of current logical cylinders
	.wCurHeads	resw 1	; 55V, Number of current logical heads
	.wCurSPT	resw 1	; 56V, Number of current logical sectors per track
	.dwCurSCnt	resd 1	; 57...58V, Current capacity in sectors

	; Words 59-63 are always valid
	.bBlockSel	resb 1	; 59[0-7]V, Current setting for number of sectors that
						;           can be transferred per interrupt on R/W multiple command
	.bBlockFlgs	resb 1	; 59[8-15]VR, bit 0 set if Multiple sector setting is valid	
	.dwLBACnt	resd 1	; 60...61F, Total number of user addressable sectors (LBA mode only)
	.bSDMASupp	resb 1	; 62[0-7]F, Single word DMA transfer modes supported
	.bSDMAAct	resb 1	; 62[8-15]V, Single word DMA transfer mode active
	.bMDMASupp	resb 1	; 63[0-7]F, Multiword DMA transfer modes supported
	.bMDMAAct	resb 1	; 63[8-15]V, Multiword DMA transfer mode active
	
	; Words 64-70 are valid only if bit1 is set in .wFields (ATA2+)
	.bPIOSupp	resb 1	; 64[0-7]F, Advanced PIO Transfer Modes Supported
				resb 1	; 64[8-15]R
	.wMDMAMinCy	resw 1	; 65F, Minimum Multiword DMA Transfer Cycle Time Per Word
	.wMDMARecCy	resw 1	; 66F, Manufacturer’s Recommended Multiword DMA Transfer Cycle Time
	.wPIOMinCy	resw 1	; 67F, Minimum PIO Transfer Cycle Time Without Flow Control
	.wPIOMinCyF	resw 1	; 68F, Minimum PIO Transfer Cycle Time With IORDY Flow Control
endstruc

; ATA-2 Word 0, General configuration
A2_wGenCfg_NONMAG		EQU	(1<<15)	; Reserved for non-magnetic drives
A2_wGenCfg_REMOVABLE	EQU	(1<<7)	; Removable media device
A2_wGenCfg_FIXED		EQU	(1<<6)	; Not removable controller and/or device

; ATA-1 Word 49, Capabilities
A2_wCaps_TIMER			EQU	(1<<13)	; Standby timer values as specified in this standard are supported
A2_wCaps_IORDY			EQU	(1<<11)	; IORDY supported
A2_wCaps_CANDISIORDY	EQU	(1<<10)	; IORDY can be disabled
A2_wCaps_LBA			EQU	(1<<9)	; LBA supported
A2_wCaps_DMA			EQU	(1<<8)	; DMA supported

; ATA-2 Word 53, Fields
A2_wFields_54to58		EQU	(1<<0)	; The fields reported in words 54-58 are valid
A2_wFields_64to70		EQU	(1<<1)	; The fields reported in words 64-70 are valid

; ATA-2 Word 59 high byte, Block mode flags
A2_bBlockFlgs_VALID		EQU	(1<<0)	; Multiple sector setting (bBlockSel) is valid

; ATA-2 Word 64, Advanced PIO transfer modes supported
A2_bPIOSupp_PIO3		EQU	(1<<0)
A2_bPIOSupp_PIO4		EQU	(1<<1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ATA-6 Drive Information struct
; F = Fixed value
; V = Variable value
; R = Reserved word
; X = Vendor specific word
struc ATA6
	.wGenCfg	resw 1	; 0F, General configuration bit-significant information
				resw 1	; 1X, Obsolete (Number of logical cylinders)
				resw 1	; 2V, Specific configuration
				resw 1	; 3X, Obsolete (Number of logical heads)
				resw 1	; 4X
				resw 1	; 5X
				resw 1	; 6X, Obsolete (Number of logical sectors per track) 
				resw 2	; 7...8V, Reserved for assignment by the CompactFlash Association
				resw 1	; 9X
	.strSerial	resb 20	; 10...19F, Serial number (20 ASCII characters, 0000h=not specified)
				resw 1	; 20X
				resw 1	; 21X
				resw 1	; 22X, Obsolete (# of ECC bytes avail on read/write long cmds (0000h=not spec'd))
	.strFirmW	resb 8	; 23...26F, Firmware revision (8 ASCII characters, 0000h=not specified)
	.strModel	resb 40	; 27...46F, Model number (40 ASCII characters, 0000h=not specified)
	.bBlckSize	resb 1	; 47[0-7]F, Maximum number of sectors that can be transferred
						;           per interrupt on read and write multiple commands
						;		    (00h=Read/write multiple commands not implemented)
				resb 1	; 47[8-15]F, 80h
				resw 1	; 48R
	.wCaps		resw 1	; 49FX, Capabilities
	.wCapsHigh	resw 1	; 50FX, Capabilities 2
				resw 1	; 51X, Obsolete (PIO data transfer cycle timing mode)
				resw 1	; 52X, Obsolete (DMA data transfer cycle timing mode)
	.wFields	resw 1	; 53FX, Field (next words) validity bits

	; Words 54-58 are valid only if bit0 is set in .wFields
				resw 1	; 54X, Obsolete (Number of current logical cylinders)
				resw 1	; 55X, Obsolete (Number of current logical heads)
				resw 1	; 56X, Obsolete (Number of current logical sectors per track)
				resd 1	; 57...58X, Obsolete (Current capacity in sectors)

	; Words 59-63 are always valid
	.bBlockSel	resb 1	; 59[0-7]V, Current setting for number of sectors that
						;           can be transferred per interrupt on R/W multiple command
	.bBlockFlgs	resb 1	; 59[8-15]VR, bit 0 set if Multiple sector setting is valid
	.dwLBACnt	resd 1	; 60...61F, Total number of user addressable sectors (LBA-28)
				resb 1	; 62[0-7]X, Obsolete (Single word DMA transfer modes supported)
				resb 1	; 62[8-15]X, Obsolete (Single word DMA transfer mode active)
	.wMDMA		resw 1	; 63FV, Multiword DMA transfer modes supported and active

	; Words 64-70 are valid only if bit1 is set in .wFields (ATA2+)
	.bPIOSupp	resb 1	; 64[0-7]F, Advanced PIO Transfer Modes Supported
				resb 1	; 64[8-15]R
	.wMDMAMinCy	resw 1	; 65F, Minimum Multiword DMA Transfer Cycle Time Per Word
	.wMDMARecCy	resw 1	; 66F, Manufacturer’s Recommended Multiword DMA Transfer Cycle Time
	.wPIOMinCy	resw 1	; 67F, Minimum PIO Transfer Cycle Time Without Flow Control
	.wPIOMinCyF	resw 1	; 68F, Minimum PIO Transfer Cycle Time With IORDY Flow Control
				resw 71-69	; 69...70R

	; Words 71...74 are reserved for IDENTIFY PACKET DEVICE command
				resw 75-71	; 71...74R

	.wQueue		resw 1	; 75[0-4]F, Maximum queue depth - 1
				resw 80-76	; 76...79R

	.wMajorVer	resw 1	; 80F, Major Version Number
	.wMinorVer	resw 1	; 81F, Minor Version Number
	.wSetSup82	resw 1	; 82F, Command set supported
	.wSetSup83	resw 1	; 83F, Command sets supported
	.wSetSup84	resw 1	; 84F, Command set / Feature supported extension
	.wEnFor82	resw 1	; 85FV, Command set / feature enabled (for word 82)
	.wEnFor83	resw 1	; 86FV, Command set / feature enabled (for word 83)
	.wEnFor84	resw 1	; 87FV, Command set / feature enabled (for word 84)

	; Word 88 is valid only if bit2 is set in .wFields (word 53)
	.wUDMA		resw 1	; 88FV, Ultra DMA Mode support

	.wEraseTime	resw 1	; 89F, Time required for security erase unit completion
	.wEnhErTime	resw 1	; 90F, Time required for Enhanced security erase completion
	.wCurPower	resw 1	; 91V, Current advanced power management value
	.wPWRev		resw 1	; 92V, Master Password Revision Code
	.wReset		resw 1	; 93FV, Hardware reset result
	.bCurAcous	resb 1	; 94[0-7]V, Current automatic acoustic management value
	.bRecAcous	resb 1	; 94[8-15]V, Vendor’s recommended acoustic management value
				resw 100-95		; 95...99R
	.qwLBACnt	resb 8	; 100...103V, Total number of user addressable sectors (LBA48)
				resw 127-104	; 104...126R
	.wRMSN		resw 1	; 127F, Removable Media Status Notification feature set support
	.wSecurity	resw 1	; 128FV, Security Status
				resw 160-129	; 129...157X, Vendor Specific
	.wCFAPower	resw 1	; 160FV, CFA Power Mode 1
				resw 176-161	; 161...175R, Reserved for assignment by the CompactFlash Association
	.strMediaSr	resw 206-176	; 176...205V, Current media serial number
				resw 255-206	; 206...254R
	.bSignature	resb 1	; 255[0-7]X, Signature
	.bChecksum	resb 1	; 255[8-15]X, Checksum
endstruc

; ATA-6 Word 0, General configuration
A6_wGenCfg_REMOVABLE	EQU	(1<<7)	; Removable media device
A6_wGenCfg_INCOMPLETE	EQU	(1<<2)	; Response incomplete

; ATA-6 Word 49, Capabilities
A6_wCaps_TIMER			EQU	(1<<13)	; Standby timer values as specified in this standard are supported
A6_wCaps_IORDY			EQU	(1<<11)	; IORDY supported
A6_wCaps_CANDISIORDY	EQU	(1<<10)	; IORDY can be disabled
A6_wCaps_LBA			EQU	(1<<9)	; LBA supported
A6_wCaps_DMA			EQU	(1<<8)	; DMA supported

; ATA-6 Word 53, Fields
A6_wFields_88			EQU	(1<<2)	; The fields reported in word 88 are valid
A6_wFields_64to70		EQU	(1<<1)	; The fields reported in words 64-70 are valid

; ATA-6 Word 59 high byte, Block mode flags
A6_bBlockFlgs_VALID		EQU	(1<<0)	; Multiple sector setting (bBlockSel) is valid

; ATA-6 Word 63, Multiword DMA Mode
A6_wMDMA_MODE2_SELECTED	EQU	(1<<10)	; Multiword DMA mode 2 is selected
A6_wMDMA_MODE1_SELECTED	EQU	(1<<9)	; Multiword DMA mode 1 is selected
A6_wMDMA_MODE0_SELECTED	EQU	(1<<8)	; Multiword DMA mode 0 is selected
A6_wMDMA_MODE2_SUPRTD	EQU	(1<<2)	; Multiword DMA mode 2 and below are supported
A6_wMDMA_MODE1_SUPRTD	EQU	(1<<1)	; Multiword DMA mode 1 and below are supported
A6_wMDMA_MODE0_SUPRTD	EQU	(1<<0)	; Multiword DMA mode 0 is supported

; ATA-6 Word 80, Major version number
A6_wMajorVer_ATA6		EQU	(1<<6)
A6_wMajorVer_ATA5		EQU	(1<<5)
A6_wMajorVer_ATA4		EQU	(1<<4)
A6_wMajorVer_ATA3		EQU	(1<<3)

; ATA-6 Word 82, Command set supported
A6_wSetSup82_NOP		EQU	(1<<14)	; NOP command supported
A6_wSetSup82_RDBUFF		EQU	(1<<13)	; READ BUFFER command supported
A6_wSetSup82_WRBUFF		EQU	(1<<12)	; WRITE BUFFER command supported
A6_wSetSup82_PROT_AREA	EQU	(1<<10)	; Host Protected Area feature set supported
A6_wSetSup82_DEV_RESET	EQU	(1<<9)	; DEVICE RESET command supported
A6_wSetSup82_SERVICE	EQU	(1<<8)	; SERVICE interrupt supported
A6_wSetSup82_RELEASE	EQU	(1<<7)	; Release interrupt supported
A6_wSetSup82_LOOKAHEAD	EQU	(1<<6)	; Look-ahead supported
A6_wSetSup82_WRCACHE	EQU	(1<<5)	; Write cache supported
A6_wSetSup82_POWERMAN	EQU	(1<<3)	; Power Management feature set supported
A6_wSetSup82_REM_MEDIA	EQU	(1<<2)	; Removable Media feature set supported
A6_wSetSup82_SECURITY	EQU	(1<<1)	; Security Mode feature set supported
A6_wSetSup82_SMART		EQU	(1<<0)	; SMART feature set supported

; ATA-6 Word 83, Command sets supported
A6_wSetSup83_FLUSH_EXT	EQU	(1<<13)	; FLUSH CACHE EXT command supported
A6_wSetSup83_FLUSH		EQU	(1<<12)	; FLUSH CACHE command supported
A6_wSetSup83_CFG		EQU	(1<<11)	; Device Configuration Overlay feature set supported
A6_wSetSup83_LBA48		EQU	(1<<10)	; 48-bit LBA feature set supported
A6_wSetSup83_ACOUSTIC	EQU	(1<<9)	; Automatic Acoustic Management feature set supported
A6_wSetSup83_SET_MAX	EQU	(1<<8)	; SET MAX security extension supported
A6_wSetSup83_FEATURES	EQU	(1<<6)	; SET FEATURES subcommand required to spinup after power-up
A6_wSetSup83_POWERUP	EQU	(1<<5)	; Power-Up In Standby feature set supported
A6_wSetSup83_RMSN		EQU	(1<<4)	; Removable Media Status Notification feature set supported
A6_wSetSup83_APM		EQU	(1<<3)	; Advanced Power Management feature set supported
A6_wSetSup83_CFA		EQU	(1<<2)	; CFA feature set supported
A6_wSetSup83_DMAQUEUED	EQU	(1<<1)	; READ/WRITE DMA QUEUED supported
A6_wSetSup83_MICROCODE	EQU	(1<<0)	; DOWNLOAD MICROCODE command supported

; ATA-6 Word 84, Command set/feature supported extension
A6_wSetSup84_GENLOG		EQU	(1<<5)	; General Purpose Logging feature set supported
A6_wSetSup84_MEDIAPASS	EQU	(1<<3)	; Media Card Pass Through Command feature set supported
A6_wSetSup84_MEDIASER	EQU	(1<<2)	; Media serial number supported
A6_wSetSup84_SMARTTEST	EQU	(1<<1)	; SMART self-test supported
A6_wSetSup84_SMARTLOG	EQU	(1<<0)	; SMART error logging supported

; ATA-6 Word 85, Command set/feature enabled (supported by word 82)
A6_wEnFor82_NOP			EQU	(1<<14)	; NOP command enabled
A6_wEnFor82_RDBUFF		EQU	(1<<13)	; READ BUFFER command enabled
A6_wEnFor82_WRBUFF		EQU	(1<<12)	; WRITE BUFFER command enabled
A6_wEnFor82_PROT_AREA	EQU	(1<<10)	; Host Protected Area feature set enabled
A6_wEnFor82_DEV_RESET	EQU	(1<<9)	; DEVICE RESET command enabled
A6_wEnFor82_SERVICE		EQU	(1<<8)	; SERVICE interrupt enabled
A6_wEnFor82_RELEASE		EQU	(1<<7)	; Release interrupt enabled
A6_wEnFor82_LOOKAHEAD	EQU	(1<<6)	; Look-ahead enabled
A6_wEnFor82_WRCACHE		EQU	(1<<5)	; Write cache enabled
A6_wEnFor82_POWERMAN	EQU	(1<<3)	; Power Management feature set enabled
A6_wEnFor82_REM_MEDIA	EQU	(1<<2)	; Removable Media feature set enabled
A6_wEnFor82_SECURITY	EQU	(1<<1)	; Security Mode feature set enabled
A6_wEnFor82_SMART		EQU	(1<<0)	; SMART feature set enabled

; ATA-6 Word 86, Command set/feature enabled (supported by word 83)
A6_wEnFor83_FLUSH_EXT	EQU	(1<<13)	; FLUSH CACHE EXT command supported
A6_wEnFor83_FLUSH		EQU	(1<<12)	; FLUSH CACHE command supported
A6_wEnFor83_CFG			EQU	(1<<11)	; Device Configuration Overlay supported
A6_wEnFor83_LBA48		EQU	(1<<10)	; 48-bit LBA feature set supported
A6_wEnFor83_ACOUSTIC	EQU	(1<<9)	; Automatic Acoustic Management feature set enabled
A6_wEnFor83_SET_MAX		EQU	(1<<8)	; SET MAX security extension enabled by SET MAX SET PASSWORD
A6_wEnFor83_FEATURES	EQU	(1<<6)	; SET FEATURES subcommand required to spinup after power-up
A6_wEnFor83_POWERUP		EQU	(1<<5)	; Power-Up In Standby feature set enabled
A6_wEnFor83_RMSN		EQU	(1<<4)	; Removable Media Status Notification feature set enabled
A6_wEnFor83_APM			EQU	(1<<3)	; Advanced Power Management feature set enabled
A6_wEnFor83_CFA			EQU	(1<<2)	; CFA feature set enabled
A6_wEnFor83_DMAQUEUED	EQU	(1<<1)	; READ/WRITE DMA QUEUED supported
A6_wEnFor83_MICROCODE	EQU	(1<<0)	; DOWNLOAD MICROCODE command supported

; ATA-6 Word 87, Command set/feature default
A6_wEnFor84_GENLOG		EQU	(1<<5)	; General Purpose Logging feature set supported
A6_wEnFor84_MEDIAPASS	EQU	(1<<3)	; Media Card Pass Through Command feature set enabled
A6_wEnFor84_MEDIASER	EQU	(1<<2)	; Media serial number is valid
A6_wEnFor84_SMARTTEST	EQU	(1<<1)	; SMART self-test supported
A6_wEnFor84_SMARTLOG	EQU	(1<<0)	; SMART error logging supported

; ATA-6 Word 88, Ultra DMA Mode
A6_wUDMA_MODE5_SELECTED	EQU	(1<<13)	; Ultra DMA mode 5 is selected
A6_wUDMA_MODE4_SELECTED	EQU	(1<<12)	; Ultra DMA mode 4 is selected
A6_wUDMA_MODE3_SELECTED	EQU	(1<<11)	; Ultra DMA mode 3 is selected
A6_wUDMA_MODE2_SELECTED	EQU	(1<<10)	; Ultra DMA mode 2 is selected
A6_wUDMA_MODE1_SELECTED	EQU	(1<<9)	; Ultra DMA mode 1 is selected
A6_wUDMA_MODE0_SELECTED	EQU	(1<<8)	; Ultra DMA mode 0 is selected
A6_wUDMA_MODE5_SUPRTD	EQU	(1<<5)	; Ultra DMA mode 5 and below are supported
A6_wUDMA_MODE4_SUPRTD	EQU	(1<<4)	; Ultra DMA mode 4 and below are supported
A6_wUDMA_MODE3_SUPRTD	EQU	(1<<3)	; Ultra DMA mode 3 and below are supported
A6_wUDMA_MODE2_SUPRTD	EQU	(1<<2)	; Ultra DMA mode 2 and below are supported
A6_wUDMA_MODE1_SUPRTD	EQU	(1<<1)	; Ultra DMA mode 1 and below are supported
A6_wUDMA_MODE0_SUPRTD	EQU	(1<<0)	; Ultra DMA mode 0 is supported

; ATA-6 Word 93, Hardware reset result
A6_wReset_CBLID_BELOW	EQU	(1<<13)	; Device detected CBLID- above ViH
A6_wReset_DEV1_PDIAG	EQU	(1<<11)	; Device 1 asserted PDIAG-
A6_wReset_DEV0_RESP_D1	EQU	(1<<6)	; Device 0 responds when Device 1 is selected
A6_wReset_DEV0_DASP		EQU	(1<<5)	; Device 0 detected the assertion of DASP-
A6_wReset_DEV0_PDIAG	EQU	(1<<4)	; Device 0 detected the assertion of PDIAG
A6_wReset_DEV0_PASSED	EQU	(1<<3)	; Device 0 passed diagnostics
A6_wReset_MASK_DEV1_DETERMINE	EQU ((1<<10)|(1<<9))	; These bits indicate how Device 1 determined the device number
A6_wReset_MASK_DEV0_DETERMINE	EQU ((1<<2)|(1<<1))		; These bits indicate how Device 0 determined the device number:
A6_wReset_RESERVED		EQU	00b
A6_wReset_JUMPER		EQU	01b		; a jumper was used
A6_wReset_CSEL			EQU	10b		; the CSEL signal was used
A6_wReset_UNKNOWN		EQU	11b		; some other method was used or the method is unknown

; ATA-6 Word 127, Removable Media Status Notification feature set support
A6_wRMSN_SUPPORTED		EQU	(1<<0)	; Removable Media Status Notification feature supported

; ATA-6 Word 128, Security status
A6_wSecurity_MAX		EQU	(1<<8)	; Security level 0 = High, 1 = Maximum
A6_wSecurity_ENH_ERASE	EQU	(1<<5)	; Enhanced security erase supported
A6_wSecurity_EXPIRED	EQU	(1<<4)	; Security count expired
A6_wSecurity_FROZEN		EQU	(1<<3)	; Security frozen
A6_wSecurity_LOCKED		EQU	(1<<2)	; Security locked
A6_wSecurity_ENABLED	EQU	(1<<1)	; Security enabled
A6_wSecurity_SUPPORTED	EQU	(1<<0)	; Security supported

; ATA-6 Word 160, CFA Power Mode 1
A6_wCFAPower_WORDSUPP	EQU	(1<<15)	; Word 160 supported
A6_wCFAPower_REQUIRED	EQU	(1<<13)	; CFA power mode 1 is required for one or more commands implemented by the device
A6_wCFAPower_DISABLED	EQU	(1<<12)	; CFA power mode 1 disabled
A6_wCFAPower_MASK_mA	EQU	0FFFh	; Maximum current in mA


%endif ; ATA_ID_INC
