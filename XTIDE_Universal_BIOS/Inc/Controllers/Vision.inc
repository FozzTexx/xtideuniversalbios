; Project name	:	XTIDE Universal BIOS
; Description	:	QDI Vision QD6500 and QD6580 VLB IDE controller
;					specifications.
;
;					Specifications can be found at http://www.ryston.cz/petr/vlb/vlbidechips.html
;					QD6580 DOS Driver Analysis: http://www.ryston.cz/petr/qd/dos37.html
%ifndef VISION_INC
%define VISION_INC

; Possible base addresses for QD6500 and QD6580
QD65XX_BASE_PORT					EQU		30h
QD65XX_ALTERNATIVE_BASE_PORT		EQU		0B0h


; Vision Register offsets from QD chip base port
QD6500_IDE_TIMING_REGISTER				EQU	0
QD6580_PRIMARY_IDE_TIMING_REGISTER		EQU	0		; QD6500 has only one channel
QD65XX_CONFIG_REGISTER_in				EQU	1
QD6580_SECONDARY_IDE_TIMING_REGISTER	EQU	2		; Same definitions as Primary IDE Timing Register
QD6580_CONTROL_REGISTER					EQU	3


; Bit definitions for QD65xx IDE Timing Register(s)
MASK_QD6500IDE_ACTIVE_TIME				EQU	7h		; Active time in VLB clocks (bits 0...2)
													; 000b = 8 clocks (<= 33 MHz), 9 clocks (>33 MHz)
													; 111b = 1 clock (<= 33 MHz), 2 clocks (>33 MHz)
MASK_QD6580IDE_ACTIVE_TIME				EQU	0Fh		; Active time in VLB clocks (bits 0...3)
													; 0000b = 17 clocks, 1111b = 2 clocks

MASK_QD6500IDE_RECOVERY_TIME			EQU	0F0h	; Recovery time in VLB clocks (bits 4...7)
													; 0000b = 18 clocks (<= 33 MHz), 15 clocks (>33 MHz)
													; 1111b = 3 clocks (<= 33 MHz), 0 clocks (>33 MHz)
MASK_QD6580IDE_RECOVERY_TIME			EQU	MASK_QD6500IDE_RECOVERY_TIME
													; 0000b = 15 clocks, 1101b = 2 clocks
POSITON_QD65XXIDE_RECOVERY_TIME			EQU	4


; Bit definitions for QD65xx Config Register (read only)
FLG_QDCONFIG_PRIMARY_IDE				EQU	(1<<0)	; IDE Controller Base Address
													; 0 = 170h, 1 = 1F0h
FLG_QDCONFIG_ALTERNATIVE_BASE			EQU	(1<<1)	; QD Vision Controller Base Address
													; 0 = 30h, 1 = B0h
FLG_QDCONFIG_ID3						EQU	(1<<2)	; VLB bus speed
													; 0 = > 33 MHz, 1 = <= 33 MHz
FLG_QDCONFIG_QD6500STATUS				EQU	(1<<3)	; QD6500 Enabled/Disabled status
													; 0 = Enabled, 1 = Disabled
MASK_QDCONFIG_CONTROLLER_ID				EQU	0F0h	; QDI Vision Controller Identification nibble

; QDI Vision Controller Identification nibbles
ID_QD6500								EQU	1100b
ID_QD6580								EQU	1010b
ID_QD6580_ALTERNATE						EQU	0101b


; Bit definitions for QD6580 Control Register
FLG_QDCONTROL_SECONDARY_DISABLED_in		EQU	(1<<0)	; 0 = Primary and Secondary IDE enabled (Primary at 1F0h and Secondary at 170h)
													; 1 = Only Primary IDE enabled (always at 1F0h)
FLG_QDCONTROL_HDONLY_in					EQU	(1<<1)	; 0 = Hard drive or ATAPI device
													; 1 = Hard drives only
FLG_QDCONTROL_NONATAPI					EQU	(1<<7)	; Set to 1 for non-ATAPI devices (hard drives,
													; probably Read ahead and/or post-write control?)
MASK_QDCONTROL_FLAGS_TO_SET			EQU	01011111b	; Bits that must be set when writing the Control Register



; Minimum and Maximum Active and Recovery Time Values
QD6500_MAX_ACTIVE_TIME_CLOCKS			EQU	8		; VLB clocks
QD6500_MIN_ACTIVE_TIME_CLOCKS			EQU	1		; VLB clocks
QD6580_MAX_ACTIVE_TIME_CLOCKS			EQU	17		; VLB clocks
QD6580_MIN_ACTIVE_TIME_CLOCKS			EQU	2		; VLB clocks
QD65xx_MAX_RECOVERY_TIME_CLOCKS			EQU	15		; VLB clocks
QD65xx_MIN_RECOVERY_TIME_CLOCKS			EQU	2		; VLB clocks


; Cycle times for different VLB bus clocks
VLB_33MHZ_CYCLE_TIME					EQU	30		; ns
VLB_40MHZ_CYCLE_TIME					EQU	25		; ns


%endif ; VISION_INC
