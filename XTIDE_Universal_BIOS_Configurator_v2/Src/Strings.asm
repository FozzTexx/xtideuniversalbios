; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	All strings.

; Section containing initialized data
SECTION .data

; Menu title
g_szProgramTitle:
	db	"Configuration and Flashing program for XTIDE Universal BIOS v1.2.0.",LF,CR,NULL
g_szXtideUniversalBiosSignature:	db	"XTIDE120",NULL
g_szBiosIsNotLoaded:				db	"BIOS is not loaded!",NULL
g_szEEPROM:							db	"EEPROM",NULL
g_szSourceAndTypeSeparator:			db	" : ",NULL
g_szUnidentified:					db	"Unidentified",NULL
g_szUnsaved:						db	" ",SINGLE_LEFT_HORIZONTAL_TO_VERTICAL,
									db	"Unsaved",SINGLE_RIGHT_HORIZONTAL_TO_VERTICAL, NULL

; Item formatting
g_szFormatItemWithoutValue:			db	"%c%s",NULL
g_szFormatItemNameWithValue:		db	"%25s%-10S",NULL


g_szNo:								db	"No",NULL
g_szYes:							db	"Yes",NULL
g_szMultichoiceBooleanFlag:
									db	"No",LF
									db	"Yes",NULL

; Exit messages
g_szDlgExitToDos:		db	"Exit to DOS?",NULL
g_szDlgSaveChanges:		db	"Do you want to save changes to XTIDE Universal BIOS image file?",NULL


; Generic dialog strings
g_szNotificationDialog:	db	"Notification.",NULL
g_szErrorDialog:		db	"Error!",NULL
g_szGenericDialogInfo:	db	"Press ENTER or ESC to close dialog.",NULL

; Flashing related strings
g_szFlashTitle:			db	"Flashing EEPROM, please wait.",NULL
g_szErrEepromTooSmall:	db	"Image is too large for selected EEPROM type!",NULL
g_szErrEepromPolling:	db	"Timeout when polling EEPROM.",LF
						db	"EEPROM was not flashed properly!",NULL
g_szErrEepromVerify:	db	"EEPROM did not return the same byte that was written.",LF
						db	"EEPROM was not flashed properly!",NULL
g_szPCFlashSuccessfull:	db	"EEPROM was written successfully.",LF
						db	"Press any key to reboot.",NULL
g_szForeignFlash:		db	"EEPROM was written successfully.",NULL


; Strings for main menu
g_szItemMainExitToDOS:	db	"Exit to DOS",NULL
g_szItemMainLoadFile:	db	"Load BIOS from file",NULL
g_szItemMainLoadROM:	db	"Load BIOS from EEPROM",NULL
g_szItemMainLoadStngs:	db	"Load old settings from EEPROM",NULL
g_szItemMainConfigure:	db	"Configure XTIDE Universal BIOS",NULL
g_szItemMainFlash:		db	"Flash EEPROM",NULL

g_szDlgMainLoadROM:		db	"Successfully loaded XTIDE Universal BIOS from EEPROM.",NULL
g_szDlgMainLoadStngs:	db	"Successfully loaded settings from EEPROM.",NULL
g_szDlgMainLoadFile:	db	"Successfully loaded file for flashing.",NULL
g_szDlgMainSaveFile:	db	"Successfully saved XTIDE Universal BIOS to file.",NULL
g_szDlgMainFileTooBig:	db	"Selected file is too big to be loaded for flashing!",NULL
g_szDlgMainLoadErr:		db	"Failed to load file!",NULL
g_szDlgMainSaveErr:		db	"Failed to save file!",NULL
g_szDlgFileTitle:		db	"Select file to be flashed.",NULL
g_szDlgFileFilter:		db	"*.*",NULL

g_szNfoMainExitToDOS:	db	"Quits XTIDE Universal BIOS Configurator.",NULL
g_szNfoMainLoadFile:	db	"Load BIOS file to be configured or flashed.",NULL
g_szNfoMainLoadROM:		db	"Load BIOS from EEPROM to be reconfigured.",NULL
g_szNfoMainLoadStngs:	db	"Load old XTIDE Universal BIOS settings from EEPROM.",NULL
g_szNfoMainConfigure:	db	"Configure XTIDE Universal BIOS settings.",NULL
g_szNfoMainFlash:		db	"Flash loaded BIOS image to EEPROM.",NULL


; Strings for XTIDE Universal BIOS configuration menu
g_szItemCfgBackToMain:	db	"Back to Main Menu",NULL
g_szItemCfgIde1:		db	"Primary IDE Controller",NULL
g_szItemCfgIde2:		db	"Secondary IDE Controller",NULL
g_szItemCfgIde3:		db	"Tertiary IDE Controller",NULL
g_szItemCfgIde4:		db	"Quaternary IDE Controller",NULL
g_szItemCfgBootMenu:	db	"Boot menu settings",NULL
g_szItemCfgFullMode:	db	"Full operating mode",NULL
g_szItemCfgStealSize:	db	"kiB to steal from RAM",NULL
g_szItemCfgIdeCnt:		db	"IDE controllers",NULL

g_szDlgCfgFullMode:		db	"Enable full operating mode?",NULL
g_szDlgCfgStealSize:	db	"How many kiB of base memory to steal for XTIDE Universal BIOS variables (1...255)?",NULL
g_szDlgCfgIdeCnt:		db	"How many IDE controllers to manage (1...5)?",NULL

g_szNfoCfgIde:			db	"IDE controller and drive configuration.",NULL
g_szNfoCfgBootMenu:		db	"Boot menu configuration.",NULL
g_szNfoCfgFullMode:		db	"Full mode supports multiple controllers and has more features.",NULL
g_szNfoCfgStealSize:	db	"How many kiB's to steal from Conventional memory for XTIDE Universal BIOS variables.",NULL
g_szNfoCfgIdeCnt:		db	"Number of IDE controllers to manage.",NULL

g_szHelpCfgFullMode:	incbin	"Configuration_FullMode.txt"
						db	NULL
g_szHelpCfgStealSize:	incbin	"Configuration_StealSize.txt"
						db	NULL


; Strings for IDE Controller menu
g_szItemBackToCfgMenu:	db	"Back to Configuration Menu",NULL
g_szItemIdeMaster:		db	"Master Drive",NULL
g_szItemIdeSlave:		db	"Slave Drive",NULL
g_szItemIdeBusType:		db	"Bus type",NULL
g_szItemIdeCmdPort:		db	"Base (cmd block) address",NULL
g_szItemIdeCtrlPort:	db	"Control block address",NULL
g_szItemIdeEnIRQ:		db	"Enable interrupt",NULL
g_szItemIdeIRQ:			db	"IRQ",NULL

g_szDlgBusType:			db	"Select type of bus where IDE Controller is connected.",NULL
g_szDlgIdeCmdPort:		db	"Enter IDE command block (base port) address.",NULL
g_szDlgIdeCtrlPort:		db	"Enter IDE control block address (usually command block + 200h).",NULL
g_szDlgIdeEnIRQ:		db	"Enable interrupt?",NULL
g_szDlgIdeIRQ:			db	"Enter IRQ channel (2...7 for 8-bit controllers, 2...15 for any other controller).",NULL

g_szNfoIdeBackToCfgMenu:db	"Back to XTIDE Universal BIOS Configuration Menu.",NULL
g_szNfoIdeMaster:		db	"Settings for Master Drive.",NULL
g_szNfoIdeSlave:		db	"Settings for Slave Drive.",NULL
g_szNfoIdeBusType:		db	"Select controller bus type.",NULL
g_szNfoIdeCmdPort:		db	"IDE Controller Command Block (base port) address.",NULL
g_szNfoIdeCtrlPort:		db	"IDE Controller Control Block address. Usually Cmd Block + 200h.",NULL
g_szNfoIdeEnIRQ:		db	"Interrupt or polling mode.",NULL
g_szNfoIdeIRQ:			db	"IRQ channel to use.",NULL

g_szHelpIdeCmdPort:		incbin	"IDE_CommandPort.txt"
						db	NULL
g_szHelpIdeCtrlPort:	incbin	"IDE_ControlPort.txt"
						db	NULL
g_szHelpIdeEnIRQ:		incbin	"IDE_EnableInterrupt.txt"
						db	NULL
g_szHelpIdeIRQ:			incbin	"IDE_IRQ.txt"
						db	NULL

g_szMultichoiceCfgBusType:
						db	"8-bit dual port (XTIDE)",LF
						db	"8-bit single port",LF
						db	"16-bit",LF
						db	"32-bit generic",NULL

g_szValueCfgBusTypeDual8b:		db	"2x8-bit",NULL
g_szValueCfgBusTypeSingle8b:	db	"1x8-bit",NULL
g_szValueCfgBusType16b:			db	"16-bit",NULL
g_szValueCfgBusType32b:			db	"32-bit",NULL


; Strings for DRVPARAMS menu
g_szItemDrvBackToIde:	db	"Back to IDE Controller Menu",NULL
g_szItemDrvBlockMode:	db	"Block Mode Transfers",NULL
g_szItemDrvUserCHS:		db	"User specified CHS",NULL
g_szItemDrvCyls:		db	"Cylinders",NULL
g_szItemDrvHeads:		db	"Heads",NULL
g_szItemDrvSect:		db	"Sectors per track",NULL

g_szDlgDrvBlockMode:	db	"Enable Block Mode Transfers?",NULL
g_szDlgDrvUserCHS:		db	"Specify (P-)CHS parameters manually?",NULL
g_szDlgDrvCyls:			db	"Enter number of P-CHS cylinders (1...16383).",NULL
g_szDlgDrvHeads:		db	"Enter number of P-CHS heads (1...16).",NULL
g_szDlgDrvSect:			db	"Enter number of sectors per track (1...63).",NULL

g_szNfoDrvBlockMode:	db	"Transfer multiple sectors per data request.",NULL
g_szNfoDrvUserCHS:		db	"Specify (P-)CHS parameters manually instead of autodetecting them.",NULL
g_szNfoDrvCyls:			db	"Number of user specified P-CHS cylinders.",NULL
g_szNfoDrvHeads:		db	"Number of user specified P-CHS heads.",NULL
g_szNfoDrvSect:			db	"Number of user specified P-CHS sectors per track.",NULL

g_szHelpDrvBlockMode:	incbin	"Drive_BlockMode.txt"
						db	NULL
g_szHelpDrvUserCHS:		incbin	"Drive_UserCHS.txt"
						db	NULL


; Strings for boot menu settings menu
g_szItemBootTimeout:	db	"Selection timeout",NULL
g_szItemBootDrive:		db	"Default boot drive",NULL
g_szItemBootDispMode:	db	"Display Mode",NULL
g_szItemBootFloppyDrvs:	db	"Number of Floppy Drives",NULL
g_szItemBootSwap:		db	"Swap boot drive numbers",NULL

g_szDlgBootTimeout:		db	"Enter Boot Menu selection timeout in BIOS timer ticks (1...1092, 0 disables timeout).",NULL
g_szDlgBootDrive:		db	"Enter default drive number (0xh for Floppy Drives, 8xh for Hard Disks, FFh for ROM boot).",NULL
g_szDlgBootDispMode:	db	"Select display mode for Boot Menu.",NULL
g_szDlgBootFloppyDrvs:	db	"Select number of Floppy Drives to display on boot menu.",NULL
g_szDlgBootSwap:		db	"Enable drive number translation?",NULL

g_szNfoBootTimeout:		db	"Menu item selection timeout in BIOS timer ticks.",NULL
g_szNfoBootDrive:		db	"Default drive on boot menu.",NULL
g_szNfoDispMode:		db	"Display Mode for Boot Menu.",NULL
g_szNfoBootFloppyDrvs:	db	"Number of Floppy Drives to display on boot menu.",NULL
g_szNfoBootSwap:		db	"Drive Number Translation (swap first drive with selected).",NULL

g_szHelpBootTimeout:	incbin	"Bootmenu_Timeout.txt"
						db	NULL
g_szHelpBootDrive:		incbin	"Bootmenu_DefaultDrive.txt"
						db	NULL
g_szHelpBootFloppyDrvs:	incbin	"Bootmenu_FloppyDrives.txt"
						db	NULL
g_szHelpBootSwap:		incbin	"Bootmenu_SwapDrives.txt"
						db	NULL

g_szMultichoiceBootDispMode:
						db	"Default",LF
						db	"40x25 Black & White",LF
						db	"40x25 Color",LF
						db	"80x25 Black & White",LF
						db	"80x25 Color",LF
						db	"80x25 Monochrome",NULL

g_szMultichoiceBootFloppyDrvs:
						db	"Autodetect",LF
						db	"1",LF
						db	"2",LF
						db	"3",LF
						db	"4",NULL

g_szValueBootDispModeDefault:	db	"Default",NULL
g_szValueBootDispModeBW40:		db	"BW40",NULL
g_szValueBootDispModeCO40:		db	"CO40",NULL
g_szValueBootDispModeBW80:		db	"BW80",NULL
g_szValueBootDispModeCO80:		db	"CO80",NULL
g_szValueBootDispModeMono:		db	"Mono",NULL

g_szValueBootFloppyDrvsAuto:	db	"Auto",NULL
g_szValueBootFloppyDrvs1:		db	"1",NULL
g_szValueBootFloppyDrvs2:		db	"2",NULL
g_szValueBootFloppyDrvs3:		db	"3",NULL
g_szValueBootFloppyDrvs4:		db	"4",NULL


; Strings for Flash menu
g_szItemFlashStart:		db	"Start flashing",NULL
g_szItemFlashEepromType:db	"EEPROM type",NULL
g_szItemFlashSDP:		db	"SDP command",NULL
g_szItemFlashAddr:		db	"EEPROM address",NULL
g_szItemFlashPageSize:	db	"Page size",NULL
g_szItemFlashChecksum:	db	"Generate checksum byte",NULL

g_szDlgFlashEepromType:	db	"Select EEPROM type.",NULL
g_szDlgFlashSDP:		db	"Select Software Data Protection command.",NULL
g_szDlgFlashAddr:		db	"Enter segment address where EEPROM is located.",NULL
g_szDlgFlashPageSize:	db	"Select write page size.",NULL
g_szDlgFlashChecksum:	db	"Generate checksum byte to the end of BIOS image?",NULL

g_szNfoFlashEepromType:	db	"EEPROM type.",NULL
g_szNfoFlashStart:		db	"Writes BIOS to EEPROM.",NULL
g_szNfoFlashSDP:		db	"Software Data Protection command.",NULL
g_szNfoFlashAddr:		db	"Address (segment) where EEPROM is located.",NULL
g_szNfoFlashPageSize:	db	"Number of bytes to write before delay.",NULL
g_szNfoFlashChecksum:	db	"Generate checksum byte to the end of BIOS image.",NULL

g_szHelpFlashSDP:		incbin	"Flash_SdpCommand.txt"
						db	NULL
g_szHelpFlashPageSize:	incbin	"Flash_PageSize.txt"
						db	NULL
g_szHelpFlashChecksum:	incbin	"Flash_Checksum.txt"
						db	NULL

g_szMultichoiceEepromType:
						db	"2816 (2 kiB)",LF
						db	"2864 (8 kiB)",LF
						db	"28256 (32 kiB)",LF
						db	"28512 (64 kiB)",NULL
g_szValueFlash2816:		db	"2816",NULL
g_szValueFlash2864:		db	"2864",NULL
g_szValueFlash28256:	db	"28256",NULL
g_szValueFlash28512:	db	"28512",NULL

g_szMultichoiceSdpCommand:
						db	"None",LF
						db	"Enable",LF
						db	"Disable",NULL
g_szValueFlashNone:		db	"None",NULL
g_szValueFlashEnable:	db	"Enable",NULL
g_szValueFlashDisable:	db	"Disable",NULL

g_szMultichoicePageSize:
						db	"1 byte",LF
						db	"2 bytes",LF
						db	"4 bytes",LF
						db	"8 bytes",LF
						db	"16 bytes",LF
						db	"32 bytes",LF
						db	"64 bytes",NULL
g_szValueFlash1byte:	db	"1 byte",NULL
g_szValueFlash2bytes:	db	"2 bytes",NULL
g_szValueFlash4bytes:	db	"4 bytes",NULL
g_szValueFlash8bytes:	db	"8 bytes",NULL
g_szValueFlash16bytes:	db	"16 bytes",NULL
g_szValueFlash32bytes:	db	"32 bytes",NULL
g_szValueFlash64bytes:	db	"64 bytes",NULL
