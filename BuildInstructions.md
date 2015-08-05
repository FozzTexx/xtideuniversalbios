**Table of Contents**


---

# Introduction #

This is a small tutorial on how to build XTIDE Universal BIOS on Windows. This tutorial is updated for XTIDE Universal BIOS v2.0.0 beta 3.


# Programs needed #

  * [TortoiseSVN](http://tortoisesvn.tigris.org/) (or any SVN client)
  * [MinGW](http://tdm-gcc.tdragon.net/) (only mingw32-make.exe is needed)
  * [NASM](http://www.nasm.us/)
  * [UPX](http://upx.sourceforge.net/) (optional)
  * [Strawperry Perl](http://strawberryperl.com/) (optional)



---

# Install Tortoise SVN #

TortoiseSVN is a subversion client that is very easy to use since it integrates nicely to Windows. It is used to download XTIDE Universal BIOS sources. Anyone can download sources from coogle.code repository but you must be a project member to commit changes back to the repository.

First [download and install TortoiseSVN](http://tortoisesvn.net/downloads.html). You can use the default settings that the installer suggests. Next you need to create folder where you want to download the sources. We name the folder _XTIDE Universal BIOS sources_ in this example.

## Downloading sources ##

Once the directory is created, open it and click right mouse button. You will find _SVN Checkout..._ from the menu.
![https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/TortoiseMenu.png](https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/TortoiseMenu.png)

URL for the repository is http://xtideuniversalbios.googlecode.com/svn/trunk/. There is no need to alter other settings so just click OK. You have now downloaded all sources from XTIDE Universal BIOS project.
![https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/SvnCheckout.png](https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/SvnCheckout.png)


## Updating sources ##

If you have already done all above and want to get latest sources, go to the source folder you have created. Click right mouse button and select _SVN Update_. Using TortoiseSVN is really this easy!



# Install MinGW #

MinGW is a free C/C++ compiler suite for Windows. We only need make utility from it but installing the whole MinGW is easier since it will add path to the environment variables automatically. Download the bundle installer ([tdm-gcc-4.6.1.exe](http://sourceforge.net/projects/tdm-gcc/files/TDM-GCC%20Installer/tdm-gcc-4.6.1.exe/download) when writing this) and install it with default settings. It will install the MinGW to C:\MinGW32. Keep this in mind since you'll want to install NASM to C:\MinGW32\bin so there will be no need to change environment path.



# Install NASM #

NASM is the assembler that is used to compile the sources. NASM v2.10 stable is what we are using when writing this. Download the [nasm-2.10-win32.zip](http://www.nasm.us/pub/nasm/releasebuilds/2.10/win32/nasm-2.10-win32.zip) and extract nasm.exe to C:\MinGW32\bin (if you installed MinGW to C:\MinGW32\).



# Install UPX (optional) #

UPX is used to compress XTIDE Universal BIOS configurator. It is needed only for release build. The only advantage is that it makes the executable size smaller.



# Install Strawberry Perl (optional) #

Strawberry Perl is required to execute optional scripts when building XTIDE Universal BIOS. Scripts include string compression (not needed unless you modify the sources) and checksum calculation. Just run the Strawberry Perl installer with default settings.



---

# Building XTIDE Universal BIOS #

Open command line window and go to the folder where you downloaded the sources with TortoiseSVN. Then go to the _XTIDE\_Universal\_BIOS_ folder. Write _mingw32-make all_ and everything should be build.

You might want to write _mingw32-make checksum_ if you installed Stawberry Perl. It will calculate checksum bytes to the binaries (You can use XTIDECFG.COM for that if you don't want to install Stawberry Perl).

You will find the binaries in _build\_ folder.


## Including and excluding optional modules ##

There are many optional modules (most of them are included in official release builds). Reason for modules is simple: it is not possible to get all features to fit in 8k ROM. Official builds are designed so that they include the features most users prefer.

It is easy to include and exclude modules but it must be done by editing makefile. Makefile specifies how the binaries are build when you execute _mingw32-make_.

Open makefile with Windows Notepad (or [Notepad++](http://notepad-plus-plus.org/)). You will now see all the modules and short description about them. The makefile looks like below for XTIDE Universal BIOS v2.0.0 beta 3:
```
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
# RELOCATE_INT13H_STACK       Relocates INT 13h stack to top of stolen conventional memory         #
# RESERVE_DIAGNOSTIC_CYLINDER Reserve one L-CHS cylinder for compatibility with old BIOSes         #
# USE_186                     Use instructions supported by 80188/80186 and V20/V30 and later      #
# USE_286                     Use instructions supported by 286 and later (defines USE_UNDOC_INTEL)#
# USE_386                     Use instructions supported by 386 and later (defines USE_286)        #
# USE_AT                      Use features supported on AT and later systems (not available on XT) #
# USE_UNDOC_INTEL             Optimizations for Intel CPU:s - do NOT use on NEC V20/V30/Sony CPU:s #
#                                                                                                  #
####################################################################################################
```

I'm sure there will be more modules in the future so always read up to date makefile for all available modules.

Scroll down the makefile to find Assembler preprocessor defines and other variables:
```
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
```

These are the only parts in the makefile that you need to edit. The defines tell what modules are included in what builds.

DEFINES\_COMMON define the modules that are included in all builds and DEFINES\_COMMON\_LARGE define additional modules for all large builds.

DEFINES\_XT, DEFINES\_XTPLUS and DEFINES\_AT define what modules are included in the 8k XT, XT+ and AT builds in addition to the ones in DEFINES\_COMMON.

DEFINES\_XT\_LARGE, DEFINES\_XTPLUS\_LARGE and DEFINES\_AT\_LARGE are for large builds (12k by default).

Finally there are DEFINES\_XT\_TINY (XT build with minimal features) and DEFINES\_386\_8K (AT build for 386+).

If you want to make your own 8k AT build, for example, modify DEFINES\_COMMON and DEFINES\_AT to include the modules you want. Then rebuild with _mingw32-make all_ or _mingw32-make checksum_.

One more thing you might want to change is the size of large build. It is 12k by default (12288 bytes). If you want 16k binary, set ROMSIZE\_LARGE to 16384. For 32k build set it to 32768.


### Module information ###

#### **MODULE\_8BIT\_IDE** ####
This module contains support for XTIDE rev 1 and 2 and Lo-tech XT-CF v2/v3/Lite PIO mode.

#### **MODULE\_8BIT\_IDE\_ADVANCED** _(requires and automatically includes MODULE\_8BIT\_IDE)_ ####
This module contains support for JR-IDE/ISA and more advanced modes for XT-CF v2.

#### **MODULE\_ADVANCED\_ATA** ####
Adds native support for VLB (and eventually PCI) IDE Controllers. At the moment there is support for QDI Vision QD6500 and QD6580 VLB IDE controllers.

#### **MODULE\_EBIOS** ####
Support for Phoenix Enhanced Disk Drive Specification. Allows to access more than 8 GB but requires support from operating system (Windows 9x and later).

#### **MODULE\_BOOT\_MENU** ####
Boot menu displays drive details and allows selecting drive more easily but essentially it has all the same features as MODULE\_HOTKEYS.  It can also be included without MODULE\_HOTKEYS, in which case the menu is always entered during the boot process.

#### **MODULE\_HOTKEYS** ####
Displays hotkeys during drive detections. Hotkeys allows boot drive selection, ROM Boot, Serial Drive Scanning and Boot Menu.

#### **MODULE\_IRQ** ####
Adds IRQ support (you also need to enable IRQ with XTIDECFG.COM). IRQs have no real benefit for DOS (but can actually slow transfer rates a bit). You might want to use IRQs with more capable operating systems.

#### **MODULE\_SERIAL** ####
Virtual hard disks using serial port. [Instructions for emulating Serial Drives with the XTIDE Universal BIOS](http://code.google.com/p/xtideuniversalbios/wiki/SerialDrives)

#### **MODULE\_SERIAL\_FLOPPY** _(requires and automatically includes MODULE\_SERIAL)_ ####
Virtual floppy drives using serial port.

#### **MODULE\_STRINGS\_COMPRESSED** ####
Use compressed strings to save space. This module should be always included.

#### **MODULE\_FEATURE\_SETS** ####
Power Management support (you also need to enable it with XTIDECFG.COM).


### Other features that affect assembly ###

#### **ELIMINATE\_CGA\_SNOW** ####
Prevents CGA snowing at the cost of a few bytes.

#### **RELOCATE\_INT13H\_STACK** ####
Relocates INT 13h stack to top of stolen conventional memory. Has no noticeable performance penalty for AT systems but might slow down XT systems. If you include this to XT builds, make sure that Full Operating Mode is enabled with XTIDECFG.COM. Otherwise stack won't be relocated.

#### **RESERVE\_DIAGNOSTIC\_CYLINDER** ####
Old BIOSes reserve one diagnostic cylinder that is not used for anything. Do not include this if you have use for one extra cylinder. Note that this can cause compatibility problems if you move drives between different systems.

#### **USE\_186, USE\_286 and USE\_386** ####
Determines what CPU instructions are allowed. USE\_186 limits instructions to those supported by 80188/80186 and NEC V20/V30. USE\_286 limits instructions for 286 compatible code and USE\_386 limits instructions for 386 compatible code. XTIDE Universal BIOS uses macros that emulate the missing instructions when necessary. Do not use any of the mentioned preprocessor directives if you want to generate 8088/8086 compatible code.

#### **USE\_UNDOC\_INTEL** ####
Allows to use undocumented Intel opcodes that are not supported by NEC V20/V30. This is defined automatically when USE\_286 or USE\_386 is defined.

#### **USE\_AT** ####
Assembles code targeted for AT systems. For example AT builds always operate in full operating mode. Another difference is that AT builds use some BIOS functions that are not available on XT systems.


---

# Building Configurator (XTIDECFG.COM) #

You should always use up to date configurator but note that configurator usually lags behind XTIDE Universal BIOS when new features are concerned.

Go to _XTIDE\_Universal\_BIOS\_Configurator\_v2_ folder and write _mingw32-make all_ to build the XTIDECFG.COM. You should write _mingw32-make release_ if you installed UPX.

Again you will find the binaries in _build\_ folder.