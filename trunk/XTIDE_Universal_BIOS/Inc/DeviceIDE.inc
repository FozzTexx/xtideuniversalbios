; Project name	:	XTIDE Universal BIOS
; Description	:	Device specific equates for IDE drives.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.		
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;

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
