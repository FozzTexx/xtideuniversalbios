###############################################################################
# Generic makefile for building BIOS binary file.                             #
# v. 1.0.0 (28.7.2007 ... 27.6.2010)                                          #
# (C) Tomi Tilli                                                              #
# aitotat@gmail.com                                                           #
#                                                                             #
# Valid makefile targets are:                                                 #
# all		Removes existing files and builds binary file in \Build           #
# build		Builds binary file in \Build                                      #
# clean		Removes all files from \Build                                     #
#                                                                             #
# Build directory must be created manually if it does not exist.              #
#                                                                             #
###############################################################################

###########################################
# Source files and destination executable #
###########################################

# Assembly source code file (*.asm):
#SRC_ASM = Src/LibraryTests.asm
SRC_ASM = Src/TimerTest.asm
#SRC_ASM = Src/LibSizeCheck.asm

# Program executable file name without extension:
PROG = test
EXTENSION = com


#######################################
# Destination and include directories #
#######################################

# Directory where binary file will be compiled to
BUILD_DIR = Build

# Subdirectories where included files are:
HEADERS = Inc/
HEADERS += Src/
HEADERS += Src/Display/
HEADERS += Src/File/
HEADERS += Src/Keyboard/
HEADERS += Src/Menu/
HEADERS += Src/Menu/Dialog/
HEADERS += Src/String/
HEADERS += Src/Time/
HEADERS += Src/Util/


#################################################################
# Assembler preprocessor defines.                               #
#################################################################
DEFINES =
DEFINES_XT = ELIMINATE_CGA_SNOW
DEFINES_XTPLUS = USE_186 ELIMINATE_CGA_SNOW
DEFINES_AT = USE_186 USE_286 USE_AT


###################
# Other variables #
###################

# Add -D in front of every preprocessor define declaration
DEFS = $(DEFINES:%=-D%)
DEFS_XT = $(DEFINES_XT:%=-D%)
DEFS_XTPLUS = $(DEFINES_XTPLUS:%=-D%)
DEFS_AT = $(DEFINES_AT:%=-D%)

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

.PHONY: all at xtplus xt clean

# Make clean debug and release versions
all: clean at xtplus xt
	@echo All done!

at:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_AT) -l"$(TARGET)_at.lst" -o"$(TARGET)_at.$(EXTENSION)"
	@echo AT version "$(TARGET)_at.$(EXTENSION)" built.

xtplus:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XTPLUS) -l"$(TARGET)_xtp.lst" -o"$(TARGET)_xtp.$(EXTENSION)"
	@echo XT plus version "$(TARGET)_xtp.$(EXTENSION)" built.

xt:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) $(DEFS_XT) -l"$(TARGET)_xt.lst" -o"$(TARGET)_xt.$(EXTENSION)"
	@echo XT version "$(TARGET)_xt.$(EXTENSION)" built.

clean:
	@$(RM) $(BUILD_DIR)\*.*
	@echo Deleted "(*.*)" from "$(BUILD_DIR)/"
