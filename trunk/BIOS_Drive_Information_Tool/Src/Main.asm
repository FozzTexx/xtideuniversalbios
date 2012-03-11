; Project name	:	BIOS Drive Information Tool
; Description	:	BIOS Drive Information Tool reads and displays
;					drive information from BIOS.

; Include .inc files
%define INCLUDE_DISPLAY_LIBRARY
%define INCLUDE_KEYBOARD_LIBRARY
%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!
%include "ATA_ID.inc"
%include "Int13h.inc"
%include "EBIOS.inc"


; Section containing code
SECTION .text

; Program first instruction.
ORG	100h						; Code starts at offset 100h (DOS .COM)
Start:
	jmp		StartBiosDriveInformationTool

; Include library and other sources
%include "AssemblyLibrary.asm"
%include "Strings.asm"
%include "Bios.asm"
%include "Print.asm"


;--------------------------------------------------------------------
; Program start
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StartBiosDriveInformationTool:
	CALL_DISPLAY_LIBRARY	InitializeDisplayContext
	mov		bl, ATTRIBUTES_NOT_USED
	mov		ax, Print_DosCharOut
	CALL_DISPLAY_LIBRARY	SetCharOutputFunctionFromAXwithAttribFlagInBL

	mov		si, g_szProgramName
	call	Print_NullTerminatedStringFromSI

	call	ReadAndDisplayAllHardDrives

	; Exit to DOS
	mov 	ax, 4C00h			; Exit to DOS
	int 	21h



ReadAndDisplayAllHardDrives:
	call	Bios_GetNumberOfHardDrivesToDX
	jc		SHORT .NoDrivesAvailable
	mov		cx, dx
	mov		dl, 80h				; First hard drive
	jmp		SHORT .DisplayFirstDrive

ALIGN JUMP_ALIGN
.DisplayNextDriveFromDL:
	mov		si, g_szPressAnyKey
	call	Print_NullTerminatedStringFromSI
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary
.DisplayFirstDrive:
	mov		si, g_szHeaderDrive
	call	Print_DriveNumberFromDLusingFormatStringInSI

	mov		si, g_szAtaInfoHeader
	call	Print_NullTerminatedStringFromSI
	call	DisplayAtaInformationForDriveDL

	mov		si, g_szOldInfoHeader
	call	Print_NullTerminatedStringFromSI
	call	DisplayOldInt13hInformationForDriveDL

	mov		si, g_szNewInfoHeader
	call	Print_NullTerminatedStringFromSI
	call	DisplayNewInt13hInformationFromDriveDL

	inc		dx
	loop	.DisplayNextDriveFromDL
.NoDrivesAvailable:
	ret


ALIGN JUMP_ALIGN
DisplayAtaInformationForDriveDL:
	push	cx
	push	dx

	call	Bios_ReadAtaInfoFromDriveDLtoBX
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipAtaInfoSinceError

	call	Print_NameFromAtaInfoInBX

	mov		cx, [bx+ATA1.wCylCnt]
	mov		dx, [bx+ATA1.wHeadCnt]
	mov		ax, [bx+ATA1.wSPT]
	call	Print_CHSfromCXDXAX

	test	WORD [bx+ATA1.wFields], A1_wFields_54to58
	jz		SHORT .SkipChsSectors
	mov		si, g_szChsSectors
	call	Print_NullTerminatedStringFromSI
	mov		si, bx
	mov		ax, [si+ATA1.dwCurSCnt]
	mov		dx, [si+ATA1.dwCurSCnt+2]
	xor		bx, bx
	call	Print_TotalSectorsFromBXDXAX
	mov		bx, si
.SkipChsSectors:

	test	WORD [bx+ATA1.wCaps], A1_wCaps_LBA
	jz		SHORT .SkipLBA28
	mov		si, g_szLBA28
	call	Print_NullTerminatedStringFromSI
	mov		si, bx
	mov		ax, [si+ATA1.dwLBACnt]
	mov		dx, [si+ATA1.dwLBACnt+2]
	xor		bx, bx
	call	Print_TotalSectorsFromBXDXAX
	mov		bx, si
.SkipLBA28:

	test	WORD [bx+ATA6.wSetSup83], A6_wSetSup83_LBA48
	jz		SHORT .SkipLBA48
	mov		si, g_szLBA48
	call	Print_NullTerminatedStringFromSI
	mov		ax, [bx+ATA6.qwLBACnt]
	mov		dx, [bx+ATA6.qwLBACnt+2]
	mov		bx, [bx+ATA6.qwLBACnt+4]
	call	Print_TotalSectorsFromBXDXAX
.SkipLBA48:
.SkipAtaInfoSinceError:
	pop		dx
	pop		cx
	ret


ALIGN JUMP_ALIGN
DisplayOldInt13hInformationForDriveDL:
	push	cx
	push	dx
	push	dx

	call	Bios_ReadOldInt13hParametersFromDriveDL
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipOldInt13hSinceError
	call	Print_CHSfromCXDXAX

	mov		si, g_szSectors
	call	Print_NullTerminatedStringFromSI
	pop		dx
	call	Bios_ReadOldInt13hCapacityFromDriveDL
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipOldInt13hSinceError
	xchg	ax, dx
	mov		dx, cx
	xor		bx, bx
	call	Print_TotalSectorsFromBXDXAX
.SkipOldInt13hSinceError:
	pop		dx
	pop		cx
	ret

	
ALIGN JUMP_ALIGN
DisplayNewInt13hInformationFromDriveDL:
	push	cx
	push	dx

	call	Bios_ReadEbiosVersionFromDriveDL
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipNewInt13hSinceError
	call	Print_EbiosVersionFromBXandExtensionsFromCX

	call	Bios_ReadEbiosInfoFromDriveDLtoDSSI
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipNewInt13hSinceError

	test	WORD [si+EDRIVE_INFO.wFlags], FLG_CHS_INFORMATION_IS_VALID
	jz		SHORT .SkipEbiosCHS
	mov		ax, [si+EDRIVE_INFO.dwCylinders]
	mov		dx, [si+EDRIVE_INFO.dwHeads]
	mov		cx, [si+EDRIVE_INFO.dwSectorsPerTrack]
	call	Print_CHSfromCXDXAX
.SkipEbiosCHS:

	push	si
	mov		si, g_szSectors
	call	Print_NullTerminatedStringFromSI
	pop		si
	mov		ax, [si+EDRIVE_INFO.qwTotalSectors]
	mov		dx, [si+EDRIVE_INFO.qwTotalSectors+2]
	mov		bx, [si+EDRIVE_INFO.qwTotalSectors+4]
	call	Print_TotalSectorsFromBXDXAX

	mov		ax, [si+EDRIVE_INFO.wSectorSize]
	mov		si, g_szNewSectorSize
	call	Print_SectorSizeFromAXusingFormatStringInSI

.SkipNewInt13hSinceError:
	pop		dx
	pop		cx
	ret
