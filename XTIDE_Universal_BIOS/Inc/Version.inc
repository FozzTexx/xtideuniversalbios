; Project name	:	XTIDE Universal BIOS
; Description	:	Version information.
%ifndef VERSION_INC
%define VERSION_INC


%define TITLE_STRING_START	"-=XTIDE Universal BIOS "
%ifdef USE_AT
	%define	TITLE_STRING_END	"(AT=-)",NULL
%elifdef USE_186
	%define	TITLE_STRING_END	"(XT+=-)",NULL
%else
	%define	TITLE_STRING_END	"(XT=-)",NULL
%endif

%define	TITLE_STRING			TITLE_STRING_START, TITLE_STRING_END
%define	ROM_VERSION_STRING		"v2.0.0",BETA,"1 (",__DATE__,")",NULL
%define	FLASH_SIGNATURE			"XTIDE200"	; Do not terminate with NULL


%endif ; VERSION_INC
