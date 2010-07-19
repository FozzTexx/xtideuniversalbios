; File name		:	IdeRegisters.inc
; Project name	:	IDE BIOS
; Created date	:	23.3.2010
; Last update	:	23.3.2010
; Author		:	Tomi Tilli
; Description	:	Equates for IDE registers, flags and commands.
%ifndef IDEREGISTERS_INC
%define IDEREGISTERS_INC

; IDE Register offsets from Command Block base port
REG_IDE_DATA			EQU		0		; Data Register
REGR_IDE_ERROR			EQU		1		; Error Register
REGW_IDE_FEAT			EQU		1		; Features Register (ATA1+)
;REGW_IDE_WRPC			EQU		1		; Write Precompensation Register (obsolete on ATA1+)
REG_IDE_CNT				EQU		2		; Sector Count Register
REG_IDE_SECT			EQU		3		; Sector Number Register (LBA 7...0)
REG_IDE_LBA_LOW			EQU		3		; LBA Low Register
REG_IDE_LOCYL			EQU		4		; Low Cylinder Register (LBA 15...8)
REG_IDE_LBA_MID			EQU		4		; LBA Mid Register
REG_IDE_HICYL			EQU		5		; High Cylinder Register (LBA 23...16)
REG_IDE_LBA_HIGH		EQU		5		; LBA High Register
REG_IDE_DRVHD			EQU		6		; Drive and Head Register (LBA 27...24)
REGR_IDE_ST				EQU		7		; Status Register
REGW_IDE_CMD			EQU		7		; Command Register
REG_IDE_HIDATA			EQU		8		; XTIDE Data High Register (actually first Control Block reg)

; IDE Register offsets from Control Block base port
; (usually Command Block base port + 200h)
REGR_IDEC_AST			EQU		6		; Alternate Status Register
REGW_IDEC_CTRL			EQU		6		; Device Control Register
;REGR_IDEC_ADDR			EQU		7		; Drive Address Register (obsolete on ATA2+)


; Bit definitions for IDE Error Register
FLG_IDE_ERR_BBK			EQU		(1<<7)	; Bad Block Detected (reserved on ATA2+, command dependent on ATA4+)
FLG_IDE_ERR_UNC			EQU		(1<<6)	; Uncorrectable Data Error (command dependent on ATA4+)
FLG_IDE_ERR_MC			EQU		(1<<5)	; Media Changed (command dependent on ATA4+)
FLG_IDE_ERR_IDNF		EQU		(1<<4)	; ID Not Found (command dependent on ATA4+)
FLG_IDE_ERR_MCR			EQU		(1<<3)	; Media Change Request (command dependent on ATA4+)
FLG_IDE_ERR_ABRT		EQU		(1<<2)	; Command Aborted
FLG_IDE_ERR_TK0NF		EQU		(1<<1)	; Track 0 Not Found (command dependent on ATA4+)
FLG_IDE_ERR_AMNF		EQU		(1<<0)	; Address Mark Not Found (command dependent on ATA4+)

; Bit definitions for IDE Drive and Head Select Register
FLG_IDE_DRVHD_LBA		EQU		(1<<6)	; LBA Addressing enabled (instead of CHS)
FLG_IDE_DRVHD_DRV		EQU		(1<<4)	; Drive Select (0=Master, 1=Slave)
MASK_IDE_DRVHD_HEAD		EQU		0Fh		; Head select bits (bits 0...3)
MASK_IDE_DRVHD_SET		EQU		0A0h	; Bits that must be set to 1 on ATA1 (reserved on ATA2+)

; Bit definitions for IDE Status Register
FLG_IDE_ST_BSY			EQU		(1<<7)	; Busy (other flags undefined when set)
FLG_IDE_ST_DRDY			EQU		(1<<6)	; Device Ready
FLG_IDE_ST_DF			EQU		(1<<5)	; Device Fault (command dependent on ATA4+)
FLG_IDE_ST_DSC			EQU		(1<<4)	; Device Seek Complete (command dependent on ATA4+)
FLG_IDE_ST_DRQ			EQU		(1<<3)	; Data Request
FLG_IDE_ST_CORR			EQU		(1<<2)	; Corrected Data (obsolete on ATA4+)
FLG_IDE_ST_IDX			EQU		(1<<1)	; Index (vendor specific on ATA2+, obsolete on ATA4+)
FLG_IDE_ST_ERR			EQU		(1<<0)	; Error

; Bit definitions for IDE Device Control Register
; Bit 0 must be zero, unlisted bits are reserved.
FLG_IDE_CTRL_O8H		EQU		(1<<3)	; Drive has more than 8 heads (pre-ATA only, 1 on ATA1, reserved on ATA2+)
FLG_IDE_CTRL_SRST		EQU		(1<<2)	; Software Reset
FLG_IDE_CTRL_nIEN		EQU		(1<<1)	; Negated Interrupt Enable (IRQ disabled when set)


; Commands for IDE Controller
;HCMD_RECALIBRATE		EQU		10h		; Recalibrate
HCMD_READ_SECT			EQU		20h		; Read Sectors (with retries)
HCMD_WRITE_SECT			EQU		30h		; Write Sectors (with retries)
HCMD_VERIFY_SECT		EQU		40h		; Read Verify Sectors (with retries)
;HCMD_FORMAT			EQU		50h		; Format track
HCMD_SEEK				EQU		70h		; Seek
;HCMD_DIAGNOSTIC		EQU		90h		; Execute Device Diagnostic
HCMD_INIT_DEV			EQU		91h		; Initialize Device Parameters
HCMD_READ_MUL			EQU		0C4h	; Read Multiple (=block)
HCMD_WRITE_MUL			EQU		0C5h	; Write Multiple (=block)
HCMD_SET_MUL			EQU		0C6h	; Set Multiple Mode (=block size)
HCMD_ID_DEV				EQU		0ECh	; Identify Device
HCMD_SET_FEAT			EQU		0EFh	; Set Features

; Set Features subcommands
HFEAT_SET_XFER_MODE		EQU		03h		; Set transfer mode based on value in Sector Count register


%endif ; IDEREGISTERS_INC
