; Project name	:	XTIDE Universal BIOS
; Description	:	Serial Server Defines

%ifndef SERIALSERVER_INC
%define SERIALSERVER_INC

%include "Serial.inc"

;
; Command codes
;
SerialServer_Command_Header					EQU		0a0h
SerialServer_Command_Write					EQU		(SerialServer_Command_Header | 3)
SerialServer_Command_Read					EQU		(SerialServer_Command_Header | 2)
SerialServer_Command_Inquire				EQU		(SerialServer_Command_Header | 0)
SerialServer_Command_Custom_Read			EQU		(SerialServer_Command_Header | 4)
SerialServer_Command_Custom_Write			EQU		(SerialServer_Command_Header | 5)

SerialServer_SubCommand_Image_SendInitiate		EQU		1
SerialServer_SubCommand_Image_SendSectors		EQU		2
SerialServer_SubCommand_Image_SendComplete		EQU		3

;
; Locations within the ATA 512-byte Inquire structure, taken from the "Vendor specific area",
; for serial port specific information that is returned by the server for an inquire.
;
; NOTE: These are byte offsets (because of the "*2"), which is more convenient here, while
;       the ATA structure defines these in terms of word offsets.
;
SerialServer_ATA_wServerVersion			EQU		(157*2)
SerialServer_ATA_wDriveFlags			EQU		(158*2)
SerialServer_ATA_wPortAndBaud			EQU		(159*2)

;
; Command structure passed to SerialServer_SendReceive.  This mirrors IDEPACK in the XTIDE Universal BIOS, 
; since that structure is passed directly without copying values into this structure.
;
struc SerialServer_Command
	.wCommandAndCustom:	
	.bCommand				resb	1

	.bCustomCommand:	
	.bDrvAndHead			resb	1	; LBA28 27...24

	.wSectorCountAndLbaLow:
	.bSectorCount			resb	1

	.bCustomData3:		
	.bSectorNumber:
	.bLbaLow				resb	1	; LBA 7...0

	.wCustomData1:		
	.bCustomData1:		
	.wCylinder:
	.wLbaMiddleAndHigh:
	.bLbaMiddle				resb	1	; LBA 15...8

	.bCustomData2:		
	.bLbaHigh				resb	1	; LBA 23...16
endstruc

%endif

