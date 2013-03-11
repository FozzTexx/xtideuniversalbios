####################################################################################################
# Makefile to build XTIDE Universal BIOS.                                                          #
#                                                                                                  #
# Valid makefile targets are:                                                                      #
# all       Removes existing files and builds binary files in \Build                               #
# small     Builds 8 kiB binaries only (without checksum)                                          #
# large     Builds 12 kiB binaries only (without checksum)                                         #
# clean     Removes all files from \Build                                                          #
# checksum* Builds all and then generates checksum byte to all binary files                        #
# strings*  Compress src\Strings.asm to src\StringsCompressed.asm                                  #
# unused*   Checks if there are any unused functions that can be removed to save space             #
#                                                                                                  #
# * at the end of target name means that Perl is required for the job.                             #
# Build directory must be created manually if it does not exist.                                   #
#                                                                                                  #
#                                                                                                  #
# Following modules can be included or excluded:                                                   #
# MODULE_8BIT_IDE             Support for 8-BIT IDE cards like XTIDE                               #
# MODULE_8BIT_IDE_ADVANCED    Support for memory mapped and DMA based cards like JRIDE and XTCF    #
# MODULE_ADVANCED_ATA         Native support for some VLB IDE controllers                          #
# MODULE_BOOT_MENU            Boot Menu for selection of drive to boot from                        #
# MODULE_EBIOS                Enhanced functions for accessing drives over 8.4 GB                  #
# MODULE_HOTKEYS              Hotkey Bar to boot from any drive                                    #
# MODULE_IRQ                  IDE IRQ support                                                      #
# MODULE_SERIAL               Virtual hard disks using serial port                                 #
# MODULE_SERIAL_FLOPPY        Virtual floppy drives using serial port (requires MODULE_SERIAL)     #
# MODULE_STRINGS_COMPRESSED   Use compressed strings to save space                                 #
# MODULE_FEATURE_SETS         Power Management support                                             #
#                                                                                                  #
# Not modules but these affect the assembly:                                                       #
# ELIMINATE_CGA_SNOW          Prevents CGA snowing at the cost of a few bytes                      #
# RELOCATE_INT13H_STACK **    Relocates INT 13h stack to beginning of stolen conventional memory   #
# RESERVE_DIAGNOSTIC_CYLINDER Reserve one L-CHS cylinder for compatibility with old BIOSes         #
# USE_186                     Use instructions supported by 80188/80186 and V20/V30 and later      #
# USE_286                     Use instructions supported by 286 and later (defines USE_UNDOC_INTEL)#
# USE_386                     Use instructions supported by 386 and later (defines USE_286)        #
# USE_AT                      Use features supported on AT and later systems (not available on XT) #
# USE_UNDOC_INTEL             Optimizations for Intel CPU:s - do NOT use on NEC V20/V30/Sony CPU:s #
#                                                                                                  #
# ** AT Builds only (when USE_AT is defined)                                                       #
####################################################################################################

###########################################
# Source files and destination executable #
###########################################

# Assembly source code file (*.asm):
SRC_ASM = Src/Main.asm

# Program executable file name without extension:
PROG = ide


#######################################
# Destination and include directories #
#######################################

# Directory where binary file will be compiled to
BUILD_DIR = Build

# Subdirectories where included files are:
HEADERS = Inc/
HEADERS += Inc/Controllers/
HEADERS += Src/
HEADERS += Src/Handlers/
HEADERS += Src/Handlers/Int13h/
HEADERS += Src/Handlers/Int13h/EBIOS/
HEADERS += Src/Handlers/Int13h/Tools/
HEADERS += Src/Handlers/Int19h/
HEADERS += Src/Device/
HEADERS += Src/Device/IDE/
HEADERS += Src/Device/MemoryMappedIDE/
HEADERS += Src/Device/Serial/
HEADERS += Src/Initialization/
HEADERS += Src/Initialization/AdvancedAta/
HEADERS += Src/Menus/
HEADERS += Src/Menus/BootMenu/
HEADERS += Src/Libraries/
HEADERS += Src/VariablesAndDPTs/

# Subdirectories where library files are:
LIBS = ../Assembly_Library/Inc/
LIBS += ../Assembly_Library/Src/
LIBS += ../Assembly_Library/Src/Display/
LIBS += ../Assembly_Library/Src/File/
LIBS += ../Assembly_Library/Src/Keyboard/
LIBS += ../Assembly_Library/Src/Menu/
LIBS += ../Assembly_Library/Src/Menu/Dialog/
LIBS += ../Assembly_Library/Src/String/
LIBS += ../Assembly_Library/Src/Time/
LIBS += ../Assembly_Library/Src/Util/
LIBS += ../Assembly_Library/Src/Serial/
LIBS += ../XTIDE_Universal_BIOS/Inc/
HEADERS += $(LIBS)


#################################################################
# Assembler preprocessor defines.                               #
#################################################################
DEFINES_COMMON = MODULE_STRINGS_COMPRESSED MODULE_HOTKEYS MODULE_8BIT_IDE MODULE_SERIAL MODULE_SERIAL_FLOPPY MODULE_EBIOS MODULE_FEATURE_SETS RESERVE_DIAGNOSTIC_CYLINDER
DEFINES_COMMON_LARGE = MODULE_BOOT_MENU MODULE_8BIT_IDE_ADVANCED

DEFINES_XT = $(DEFINES_COMMON) ELIMINATE_CGA_SNOW MODULE_8BIT_IDE_ADVANCED
DEFINES_XTPLUS = $(DEFINES_COMMON) $(DEFINES_XT) USE_186
DEFINES_AT = $(DEFINES_COMMON) USE_AT USE_286 RELOCATE_INT13H_STACK MODULE_IRQ MODULE_ADVANCED_ATA

DEFINES_XT_LARGE = $(DEFINES_XT) $(DEFINES_COMMON_LARGE)
DEFINES_XTPLUS_LARGE = $(DEFINES_XTPLUS) $(DEFINES_COMMON_LARGE)
DEFINES_AT_LARGE = $(DEFINES_AT) $(DEFINES_COMMON_LARGE)

DEFINES_XT_TINY = MODULE_STRINGS_COMPRESSED MODULE_8BIT_IDE
DEFINES_386_8K = $(DEFINES_AT) USE_386

DEFINES_ALL_FEATURES = MODULE_8BIT_IDE MODULE_8BIT_IDE_ADVANCED MODULE_ADVANCED_ATA MODULE_EBIOS MODULE_BOOT_MENU MODULE_HOTKEYS MODULE_IRQ MODULE_SERIAL MODULE_SERIAL_FLOPPY MODULE_STRINGS_COMPRESSED MODULE_FEATURE_SETS


###################
# Other variables #
###################

# Target size of the ROM, used in main.asm for number of 512B blocks and by checksum Perl script below
BIOS_SIZE = 8192		# For BIOS header (use even multiplier!)
ROMSIZE = $(BIOS_SIZE)	# Size of binary to build when building with make checksum
BIOS_SIZE_LARGE = 12288
ROMSIZE_LARGE = $(BIOS_SIZE_LARGE)

# Add -D in front of every preprocessor define declaration
DEFS_XT = $(DEFINES_XT:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE)
DEFS_XTPLUS = $(DEFINES_XTPLUS:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE)
DEFS_AT = $(DEFINES_AT:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE)
DEFS_XT_LARGE = $(DEFINES_XT_LARGE:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE_LARGE)
DEFS_XTPLUS_LARGE = $(DEFINES_XTPLUS_LARGE:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE_LARGE)
DEFS_AT_LARGE = $(DEFINES_AT_LARGE:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE_LARGE)
DEFS_XT_TINY = $(DEFINES_XT_TINY:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE)
DEFS_386_8K = $(DEFINES_386_8K:%=-D%) -DBIOS_SIZE=$(BIOS_SIZE)
DEFS_ALL_FEATURES = $(DEFINES_ALL_FEATURES:%=-D%)

# Add -I in front of all header directories
IHEADERS = $(HEADERS:%=-I%)

# Path + target file to be built
TARGET = $(BUILD_DIR)/$(PROG)

#########################
# Compilers and linkers #
#########################

# Make
MAKE = mingw32-make.exe

# Assembler
AS = nasm.exe

# use this command to erase files.
RM = -del /Q


#############################
# Compiler and linker flags #
#############################

# Assembly compiler flags
ASFLAGS = -f bin				# Produce binary object files
ASFLAGS += $(IHEADERS)			# Set header file directory paths
ASFLAGS += -Worphan-labels		# Warn about labels without colon
ASFLAGS += -Ox					# Optimize operands to their shortest forms


############################################
# Build process. Actual work is done here. #
############################################

all: clean small large
	@echo All done!

small: xt_tiny xt xtplus at 386_8k
	@echo All small binaries built!

large: xt_large xtplus_large at_large
	@echo All large binaries built!

at:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT) -l"$(TARGET)_at.lst" -o"$(TARGET)_at.bin"
	@echo * Small AT version "$(TARGET)_at.bin" built.

at_large:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT_LARGE) -l"$(TARGET)_atl.lst" -o"$(TARGET)_atl.bin"
	@echo *Large AT version "$(TARGET)_atl.bin" built.

xtplus:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XTPLUS) -l"$(TARGET)_xtp.lst" -o"$(TARGET)_xtp.bin"
	@echo * Small XT Plus version "$(TARGET)_xtp.bin" built.

xtplus_large:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XTPLUS_LARGE) -l"$(TARGET)_xtpl.lst" -o"$(TARGET)_xtpl.bin"
	@echo *Large XT Plus version "$(TARGET)_xtpl.bin" built.

xt:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT) -l"$(TARGET)_xt.lst" -o"$(TARGET)_xt.bin"
	@echo * Small XT version "$(TARGET)_xt.bin" built.

xt_large:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT_LARGE) -l"$(TARGET)_xtl.lst" -o"$(TARGET)_xtl.bin"
	@echo *Large XT version "$(TARGET)_xtl.bin" built.

xt_tiny:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT_TINY) -l"$(TARGET)_tiny.lst" -o"$(TARGET)_tiny.bin"
	@echo * Tiny XT version "$(TARGET)_tiny.bin" built.

386_8k:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_386_8K) -l"$(TARGET)_386.lst" -o"$(TARGET)_386.bin"
	@echo * Small 386 version "$(TARGET)_386.bin" built.

strings: src\Strings.asm
	@$(AS) src\Strings.asm $(ASFLAGS) $(DEFS_AT_LARGE) -DCHECK_FOR_UNUSED_ENTRYPOINTS -DMODULE_STRINGS_COMPRESSED_PRECOMPRESS -o build\Strings.bin -l build\StringsPrecompress.lst
	@perl ..\tools\StringsCompress.pl < build\StringsPrecompress.lst > src\StringsCompressed.asm
	@echo StringsCompressed.asm updated!

clean:
	@$(RM) $(BUILD_DIR)\*.*
	@echo Deleted "(*.*)" from "$(BUILD_DIR)/"

checksum: all
	@perl ..\tools\checksum.pl $(TARGET)_tiny.bin $(ROMSIZE)
	@perl ..\tools\checksum.pl $(TARGET)_xt.bin $(ROMSIZE)
	@perl ..\tools\checksum.pl $(TARGET)_xtp.bin $(ROMSIZE)
	@perl ..\tools\checksum.pl $(TARGET)_at.bin $(ROMSIZE)
	@perl ..\tools\checksum.pl $(TARGET)_xtl.bin $(ROMSIZE_LARGE)
	@perl ..\tools\checksum.pl $(TARGET)_xtpl.bin $(ROMSIZE_LARGE)
	@perl ..\tools\checksum.pl $(TARGET)_atl.bin $(ROMSIZE_LARGE)
	@perl ..\tools\checksum.pl $(TARGET)_386.bin $(ROMSIZE)

unused:
	@echo "All Features"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_ALL_FEATURES) $(DEFS_XT) $(DEFS_XT_PLUS) $(DEFS_AT) $(DEFS_XT_LARGE) $(DEFS_XTPLUS_LARGE) $(DEFS_AT_LARGE) $(DEFS_XT_TINY) $(DEFS_386_8K) -o"$(TARGET)_unused.asm" -l"$(TARGET)_unused.lst"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_ALL_FEATURES) $(DEFS_XT) $(DEFS_XT_PLUS) $(DEFS_AT) $(DEFS_XT_LARGE) $(DEFS_XTPLUS_LARGE) $(DEFS_AT_LARGE) $(DEFS_XT_TINY) $(DEFS_386_8K) -o"$(TARGET)_unused.asm" -E -DCHECK_FOR_UNUSED_ENTRYPOINTS
	@perl ..\tools\unused.pl $(TARGET)_unused.lst $(TARGET)_unused.asm
	@echo "XT Small"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT) -o"$(TARGET)_unused_xt.asm" -l"$(TARGET)_unused_xt.lst"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT) -o"$(TARGET)_unused_xt.asm" -E -DCHECK_FOR_UNUSED_ENTRYPOINTS
	@perl ..\tools\unused.pl $(TARGET)_unused_xt.lst $(TARGET)_unused_xt.asm
	@echo "XT Large"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT_LARGE) -o"$(TARGET)_unused_xtl.asm" -l"$(TARGET)_unused_xtl.lst"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT_LARGE) -o"$(TARGET)_unused_xtl.asm" -E -DCHECK_FOR_UNUSED_ENTRYPOINTS
	@perl ..\tools\unused.pl $(TARGET)_unused_xtl.lst $(TARGET)_unused_xtl.asm
	@echo "AT Small"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT) -o"$(TARGET)_unused_at.asm" -l"$(TARGET)_unused_at.lst"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT) -o"$(TARGET)_unused_at.asm" -E -DCHECK_FOR_UNUSED_ENTRYPOINTS
	@perl ..\tools\unused.pl $(TARGET)_unused_at.lst $(TARGET)_unused_at.asm
	@echo "AT Large"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT_LARGE) -o"$(TARGET)_unused_atl.asm" -l"$(TARGET)_unused_atl.lst"
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT_LARGE) -o"$(TARGET)_unused_atl.asm" -E -DCHECK_FOR_UNUSED_ENTRYPOINTS
	@perl ..\tools\unused.pl $(TARGET)_unused_atl.lst $(TARGET)_unused_atl.asm


