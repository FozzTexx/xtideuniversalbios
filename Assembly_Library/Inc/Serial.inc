; Project name	:	AssemblyLibrary
; Description	:	Defines for display library.

%ifndef SERIAL_INC
%define SERIAL_INC

;--------------- UART Equates -----------------------------
;
; Serial Programming References:
;    http://en.wikibooks.org/wiki/Serial_Programming
;

Serial_UART_base						EQU		0
Serial_UART_transmitByte				EQU		0
Serial_UART_receiveByte					EQU		0

;
; Values for UART_divisorLow:
; 60h = 1200, 30h = 2400, 18h = 4800, 0ch = 9600, 6 = 19200, 4 = 28800, 3 = 38400, 2 = 57600, 1 = 115200
;
Serial_UART_divisorLow					EQU		0

;
; UART_divisorHigh is zero for all speeds including and above 1200 baud (which is all we do)
;
Serial_UART_divisorHigh					EQU		1

Serial_UART_interruptIdent				EQU		2
Serial_UART_FIFOControl					EQU		2

Serial_UART_lineControl					EQU		3

Serial_UART_modemControl				EQU		4

Serial_UART_lineStatus					EQU		5

Serial_UART_modemStatus					EQU		6

Serial_UART_scratch						EQU		7

;----------------------------------------------------------------------
;
; COM Number to I/O Port Address Mapping
;
; COM Number:                               1,    2,    3,    4,    5,    6,    7,    8,    9,   10,   11,   12
; Corresponds to I/O port:                3f8,  2f8,  3e8,  2e8,  2f0,  3e0,  2e0,  260,  368,  268,  360,  270
; Corresponds to Packed I/O port (hex):    37,   17,   35,   15,   16,   34,   14,    4,   25,    5,   24,    6
;
SERIAL_COM1_IOADDRESS	EQU		3f8h
SERIAL_COM2_IOADDRESS	EQU		2f8h
SERIAL_COM3_IOADDRESS	EQU		3e8h
SERIAL_COM4_IOADDRESS	EQU		2e8h
SERIAL_COM5_IOADDRESS	EQU		2f0h
SERIAL_COM6_IOADDRESS	EQU		3e0h
SERIAL_COM7_IOADDRESS	EQU		2e0h
SERIAL_COM8_IOADDRESS	EQU		260h
SERIAL_COM9_IOADDRESS	EQU		368h
SERIAL_COMA_IOADDRESS	EQU		268h
SERIAL_COMB_IOADDRESS	EQU		360h
SERIAL_COMC_IOADDRESS	EQU		270h

%endif
