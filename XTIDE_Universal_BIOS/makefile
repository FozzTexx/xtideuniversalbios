###############################################################################
# Makefile to build XTIDE Universal BIOS.                                     #
#                                                                             #
# Valid makefile targets are:                                                 #
# all		Removes existing files and builds binary files in \Build          #
# small		Builds 8 kiB binaries only (without checksum)                     #
# large		Builds 15 kiB binaries only (without checksum)                    #
# clean		Removes all files from \Build                                     #
# checksum*	Builds all and then generates checksum byte to all binary files   #
# strings*	Compress src\strings.asm to src\StringsCompressed.asm             #
#                                                                             #
# * at the end of target name means that Perl is required for the job.        #
# Build directory must be created manually if it does not exist.              #
#                                                                             #
###############################################################################

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
HEADERS += Src/Boot/
HEADERS += Src/Handlers/
HEADERS += Src/Handlers/Int13h/
HEADERS += Src/Handlers/Int13h/EBIOS/
HEADERS += Src/Handlers/Int13h/Tools/
HEADERS += Src/Device/
HEADERS += Src/Device/IDE/
HEADERS += Src/Device/MemoryMappedIDE/
HEADERS += Src/Device/Serial/
HEADERS += Src/Initialization/
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
DEFINES = INCLUDE_MENU_LIBRARY EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS MODULE_EBIOS MODULE_STRINGS_COMPRESSED
DEFINES_XT = ELIMINATE_CGA_SNOW MODULE_SERIAL MODULE_SERIAL_FLOPPY
DEFINES_XTPLUS = ELIMINATE_CGA_SNOW USE_186 MODULE_SERIAL MODULE_SERIAL_FLOPPY
DEFINES_AT = USE_286 USE_AT MODULE_ADVANCED_ATA
DEFINES_XT_LARGE = $(DEFINES_XT) MODULE_JRIDE
DEFINES_XTPLUS_LARGE = $(DEFINES_XTPLUS) MODULE_JRIDE
DEFINES_AT_LARGE = $(DEFINES_AT) MODULE_JRIDE
DEFINES_JRIDE_8K = ELIMINATE_CGA_SNOW MODULE_JRIDE


###################
# Other variables #
###################

# Target size of the ROM, used in main.asm for number of 512B blocks and by checksum Perl script below
ROMSIZE = 8192
ROMSIZE_LARGE = 15360

# Add -D in front of every preprocessor define declaration
DEFS = $(DEFINES:%=-D%)
DEFS_XT = $(DEFINES_XT:%=-D%) -DROMSIZE=$(ROMSIZE)
DEFS_XTPLUS = $(DEFINES_XTPLUS:%=-D%) -DROMSIZE=$(ROMSIZE)
DEFS_AT = $(DEFINES_AT:%=-D%) -DROMSIZE=$(ROMSIZE)
DEFS_XT_LARGE = $(DEFINES_XT_LARGE:%=-D%) -DROMSIZE=$(ROMSIZE_LARGE)
DEFS_XTPLUS_LARGE = $(DEFINES_XTPLUS_LARGE:%=-D%) -DROMSIZE=$(ROMSIZE_LARGE)
DEFS_AT_LARGE = $(DEFINES_AT_LARGE:%=-D%) -DROMSIZE=$(ROMSIZE_LARGE)
DEFS_JRIDE_8K = $(DEFINES_JRIDE_8K:%=-D%) -DROMSIZE=$(ROMSIZE)

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
ASFLAGS += $(DEFS)				# Preprocessor defines
ASFLAGS += $(IHEADERS)			# Set header file directory paths
ASFLAGS += -Worphan-labels		# Warn about labels without colon
ASFLAGS += -O9					# Optimize operands to their shortest forms


############################################
# Build process. Actual work is done here. #
############################################

all: clean small large
	@echo All done!

small: at xtplus xt jride_8k
	@echo All 8 kiB binaries built!

large: at_large xtplus_large xt_large
	@echo All 15 kiB binaries built!

at:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT) -l"$(TARGET)_at.lst" -o"$(TARGET)_at.bin"
	@echo * 8k AT version "$(TARGET)_at.bin" built.

at_large:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT_LARGE) -l"$(TARGET)_atl.lst" -o"$(TARGET)_atl.bin"
	@echo *15k AT version "$(TARGET)_atl.bin" built.

xtplus:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XTPLUS) -l"$(TARGET)_xtp.lst" -o"$(TARGET)_xtp.bin"
	@echo * 8k XT Plus version "$(TARGET)_xtp.bin" built.

xtplus_large:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XTPLUS_LARGE) -l"$(TARGET)_xtpl.lst" -o"$(TARGET)_xtpl.bin"
	@echo *15k XT Plus version "$(TARGET)_xtpl.bin" built.

xt:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT) -l"$(TARGET)_xt.lst" -o"$(TARGET)_xt.bin"
	@echo * 8k XT version "$(TARGET)_xt.bin" built.

xt_large:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT_LARGE) -l"$(TARGET)_xtl.lst" -o"$(TARGET)_xtl.bin"
	@echo *15k XT version "$(TARGET)_xtl.bin" built.

jride_8k:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_JRIDE_8K) -l"$(TARGET)_jr8k.lst" -o"$(TARGET)_jr8k.bin"
	@echo * 8k JR-IDE/ISA version "$(TARGET)_jr8k.bin" built.

strings: src\Strings.asm
	@$(AS) src\Strings.asm $(ASFLAGS) $(DEFS_XT) -DCHECK_FOR_UNUSED_ENTRYPOINTS -DMODULE_STRINGS_COMPRESSED_PRECOMPRESS -o build\Strings.bin -l build\StringsPrecompress.lst
	@perl ..\tools\StringsCompress.pl < build\StringsPrecompress.lst > src\StringsCompressed.asm
	@echo StringsCompressed.asm updated!

clean:
	@$(RM) $(BUILD_DIR)\*.*
	@echo Deleted "(*.*)" from "$(BUILD_DIR)/"

checksum: all
	@perl ..\tools\checksum.pl $(TARGET)_atl.bin $(ROMSIZE_LARGE)
	@perl ..\tools\checksum.pl $(TARGET)_xtpl.bin $(ROMSIZE_LARGE)
	@perl ..\tools\checksum.pl $(TARGET)_xtl.bin $(ROMSIZE_LARGE)
	@perl ..\tools\checksum.pl $(TARGET)_at.bin $(ROMSIZE)
	@perl ..\tools\checksum.pl $(TARGET)_xtp.bin $(ROMSIZE)
	@perl ..\tools\checksum.pl $(TARGET)_xt.bin $(ROMSIZE)
	@perl ..\tools\checksum.pl $(TARGET)_jr8k.bin $(ROMSIZE)

xt_unused: xt
	$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT) -o"$(TARGET)_xt_unused.asm" -E -DCHECK_FOR_UNUSED_ENTRYPOINTS
	perl ..\tools\unused.pl $(TARGET)_xt.lst $(TARGET)_xt_unused.asm

