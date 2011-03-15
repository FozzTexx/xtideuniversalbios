###############################################################################
# Generic makefile for building Assembly binary file.                         #
# v. 1.0.0 (28.7.2007 ... 28.7.2007)                                          #
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
SRC_ASM = Src\Main.asm

# Program executable file name without extension:
PROG = idecfg


#######################################
# Destination and include directories #
#######################################

# Directory where binary file will be compiled to
BUILD_DIR = Build

# Subdirectories where included files are:
HEADERS = Inc/
HEADERS += Src/
HEADERS += Src/Libraries/
HEADERS += Src/Libraries/menu/
HEADERS += Src/Menupages/
HEADERS += Src/Menupages/Values/


#################################################################
# Assembler preprocessor defines.                               #
#################################################################
DEFINES =


###################
# Other variables #
###################

# Add -D in front of every preprocessor define declaration
DEFS = $(DEFINES:%=-D%)

# Add -I in front of all header directories
# and also set to search headers from current directory
IHEADERS = $(HEADERS:%=-I%)
IHEADERS += -I.

# Path + target file to be built
TARGET = $(BUILD_DIR)\$(PROG).com


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

.PHONY: all clean build release

# Make clean debug and release versions
all:
	@$(MAKE) clean
	@$(MAKE) build
	@echo All done!

# Clean
clean:
	@$(RM) $(BUILD_DIR)\*.*
	@echo Deleted "(*.*)" from "$(BUILD_DIR)\"

# Build
build:
	@$(AS) "$(SRC_ASM)" $(ASFLAGS) -l"$(BUILD_DIR)\$(PROG).lst" -o"$(TARGET)"
	@echo "$(TARGET)" built.

release: build
	@echo Compressing with UPX...
	@upx -qq --8086 --ultra-brute $(TARGET)
	@echo Done! $(TARGET) is ready for release.
