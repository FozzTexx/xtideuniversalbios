; Project name	:	XTIDE Universal BIOS
; Description	:	Device specific equates for IDE drives.
%ifndef DEVICEIDE_INC
%define DEVICEIDE_INC

; Reset delays
HSR0_RESET_WAIT_US		EQU		5		; Delay at least 5us
HSR1_RESET_WAIT_US		EQU		2000	; Delay at least 2ms

; Polling timeout delays (system timer ticks, 1 tick = 54.9 ms)
TIMEOUT_BSY				EQU		(2000/55)	; 2000 ms
TIMEOUT_DRDY			EQU		(2000/55)	; 2000 ms
TIMEOUT_DRQ				EQU		255			;   14 s (some CF cards occasionally have long write delays)
TIMEOUT_IDENTIFY_DEVICE	EQU		(500/55)	;  500 ms
TIMEOUT_MOTOR_STARTUP	EQU		(10000/55)	;   10 s


%endif ; DEVICEIDE_INC
