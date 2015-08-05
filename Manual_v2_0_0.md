**Table of Contents**


---


# Introduction #

XTIDE Universal BIOS makes it possible to use modern large ATA hard disks or Compact Flash cards on old PC's. You can then enjoy quiet or noiseless drives with more capacity than you'll ever need for old computers.

XTIDE Universal BIOS can be used on any IBM PC, XT, AT or 100% compatible system. On AT systems you can use any 16-bit ISA or VLB IDE or Multi I/O controller. For XT systems you can use XTIDE rev1 (not available anymore), http://www.vintage-computer.com/vcforum/showthread.php?29202-XTIDE-Rev2 or https://www.retrotronics.org/home-page/jride/.

## License ##

XTIDE Universal BIOS and associated tools are Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
[GNU General Public License](License.md) for more details.


## Features ##

Some of the features included in XTIDE Universal BIOS are...
  * Supports up to 4 IDE controllers
  * Support for virtual drives via serial port, [more information](SerialDrives.md)
  * Supports drives with any capacity (MS-DOS 7.x (Windows 9x) or FreeDOS is required to access more than 8.4 GB)
  * PIO transfers with block mode support
  * Hard disk autodetection
  * Autodetected capacity, both CHS and LBA, can be overridden to make drive appear smaller than it actually is
  * Hotkeys and optional Boot menu (included in official 12k builds) for selecting any floppy drive or hard disk to boot from, including hard disks that are not handled by XTIDE Universal BIOS
  * Compact Flash and Microdrive support
  * Support for most 8-, 16-, and 32-bit IDE controllers
  * Native support for QDI Vision QD6500 and QD6580 VLB IDE controllers
...and many more.


## Different builds ##

XTIDE Universal BIOS includes many modules and features that are optional. It is not possible to include them all into 8k builds. Officially released builds include modules that benefits most people. You can quite easily make your own build to include the features that you need if you are not satisfied on the official builds.

### Modules included in officially released builds ###

[See build instructions for module descriptions](http://code.google.com/p/xtideuniversalbios/wiki/BuildInstructions).

|File|Description|MODULE\_8BIT\_IDE\_ADVANCED|MODULE\_ADVANCED\_ATA|MODULE\_BOOT\_MENU|MODULE\_IRQ|ELIMINATE\_CGA\_SNOW|RELOCATE\_INT13H\_STACK|USE\_186|USE\_286|USE\_AT|
|:---|:----------|:--------------------------|:--------------------|:-----------------|:----------|:-------------------|:----------------------|:-------|:-------|:------|
|ide\_xt.bin|8088/8086 compatible 8 kiB XT build|√                          |-                    |-                 |-          |√                   |-                      |-       |-       |-      |
|ide\_xtp.bin|8 kiB XT+ build requiring 80188/80186 or better|√                          |-                    |-                 |-          |√                   |-                      |√       |-       |-      |
|ide\_at.bin|8 kiB AT build requiring 286 or better|-                          |√                    |-                 |√          |-                   |√                      |√       |√       |√      |
|ide\_xtl.bin|8088/8086 compatible 12 kiB XT build|√                          |-                    |√                 |-          |√                   |-                      |-       |-       |-      |
|ide\_xtpl.bin|12 kiB XT+ build requiring 80188/80186 or better|√                          |-                    |√                 |-          |√                   |-                      |√       |-       |-      |
|ide\_atl.bin|12 kiB AT build requiring 286 or better|√                          |√                    |√                 |√          |-                   |√                      |√       |√       |√      |

All official builds include the following modules and features:
MODULE\_STRINGS\_COMPRESSED, MODULE\_HOTKEYS, MODULE\_EBIOS, MODULE\_SERIAL, MODULE\_SERIAL\_FLOPPY, MODULE\_FEATURE\_SETS and RESERVE\_DIAGNOSTIC\_CYLINDER


---

# Installing XTIDE Universal BIOS #

## Important if you are upgrading from any previous XTIDE Universal BIOS version ##

The v2.0.0 beta 2 and later versions, like most other BIOSes, adheres to the Phoenix Enhanced Disk Drive Specification. The older v1.x.x versions and v2.0.0 beta 1 do NOT - they may generate different L-CHS parameters for many drives. If you move a drive handled by a v1.x.x or v2.0.0 beta 1 BIOS to another system or upgrade to v2.x.x you risk data corruption if different L-CHS parameters are used.

IMPORTANT! This means that, after upgrading to XTIDE Universal BIOS v2.0.0 beta 2 or later, you need to re-create and format any partitions on drives handled by this BIOS.


## Hardware supporting XTIDE Universal BIOS ROM ##

The most convenient way to use XTIDE Universal BIOS is to use an [XTIDE card](http://www.vintage-computer.com/vcforum/showwiki.php?title=XTIDE+Rev2) or [Lo-tech XT-CF](http://www.lo-tech.co.uk/). They can be used on any PC with a free 8-bit ISA slot. You might not want to connect any drives to them in 16- or 32-bit systems since 8-bit transfers will be very slow. Using the XTIDE card allows EEPROM flashing so it is really easy to update XTIDE Universal BIOS.

Another option is to use any card with a free ROM socket for 8 kiB or larger ROMs. Official XTIDE builds are meant for 8 kiB and 16 kiB ROMs but you can burn it on a larger ROM if you append enough zeroes to the end (only append zeroes so checksum does not change). Many network cards have unused ROM sockets and there are also a few multi I/O cards and IDE controllers with ROM sockets. These cards remains fully usable even if you place a ROM with XTIDE Universal BIOS on them.

You don't need an EPROM/EEPROM programmer if you already have an XTIDE card. The XTIDE card can be used to flash additional EEPROMs (8 kiB 2864) that can then be moved to EPROM (8 kiB 2764) sockets.


## Configuring and flashing ##

The XTIDE Universal BIOS comes with a DOS utility called XTIDECFG.COM. It's primary purpose is to configure and flash the XTIDE Universal BIOS but it can also be used as a generic EEPROM flasher supporting EEPROM sizes up to 32 kiB. XTIDECFG.COM also allows saving changes to XTIDE Universal BIOS images for later programming with other devices or programming software.


## Other things to know ##

CTRL can be held down to skip XTIDE Universal BIOS initialization. Press CTRL when the POST OK beep is heard or just before the memory test has completed.


---

# Using XTIDECFG.COM (XTIDE Universal BIOS configuration and flashing program) #

XTIDECFG.COM is intended to be user friendly. At the bottom of the screen appears quick information for each menu item. Pressing F1 displays more detailed help for menu items (some menu items do not have detailed help available). Up, Down, PgUp, PgDn, Home and End keys are used for menu navigation. Enter selects the highlighted menu item and Esc returns to the previous menu.

Some menu items appear only when needed to make configuring easier.


## Menu items on "Main Menu" ##
  * Copyright and License Information
> > Displays just that.
  * Load BIOS from file
> > Loads any (not just XTIDE Universal BIOS) file to be flashed.
  * Load BIOS from EEPROM
> > Loads XTIDE Universal BIOS from EEPROM to be reconfigured if a supported version of the BIOS is found in the system.
  * Load old settings from EEPROM
> > Loads current settings from EEPROM if a supported version of the XTIDE Universal BIOS is found in the system.
  * Configure XTIDE Universal BIOS
> > This is for configuring the XTIDE Universal BIOS. This menu item appears only when a supported version of the BIOS is loaded.
  * Flash EEPROM
> > This menu item appears when a file has been loaded.
  * Save BIOS back to original file
  * Exit to DOS
> > Exits to DOS. If you have made configuration changes, then a dialog will be displayed asking if you want to save them. You can also exit to DOS by pressing Esc at the main menu.
  * Web Links

## Menu items on "Flash EEPROM" submenu ##
  * Start flashing
  * EEPROM type [default=2864]
> > Selects EEPROM type. XTIDE rev1 uses 2864 (8 kiB) EEPROM. Select 2864mod if you have done the A0-A3 address line swap mod (aka the Chuck(G) mod) to your XTIDE card.
  * SDP command [default=Enable]
> > Selects Software Data Protect command to be written before every page. You should set it to Enable if the EEPROM supports SDP.
  * Page size [default=1]
> > Larger page sizes makes flashing faster. You'll probably want to select the largest that your EEPROM supports. Slow XT systems might not be fast enough for large page sizes.
  * EEPROM address [default=D000h]
> > Segment address where the EEPROM is located. Supported versions of XTIDE Universal BIOS will be detected automatically.
  * Generate checksum byte [default=Yes]
> > This option will generate a checksum byte at the end of the EEPROM. You'll want to enable this if you have done any changes to the XTIDE Universal BIOS settings.

## Menu items on "Configure XTIDE Universal BIOS" submenu ##
  * Back to Main Menu
  * Primary IDE Controller
  * Secondary IDE Controller
  * Tertiary IDE Controller
  * Quaternary IDE Controller
> > Each "xxx IDE Controller" submenu displays IDE controller specific settings. "IDE controllers" menu item specifies the visible "xxx IDE Controller" submenus.
  * Boot settings
> > Opens submenu for boot related settings such as should boot menu be enabled etc.
  * `*`Auto Configure
> > Tries to automatically detect controllers and sets settings accordingly.
  * Full operating mode [default=No for XT builds, not available for AT builds]
> > "Full operating mode" reserves a bit of Conventional memory for XTIDE Universal BIOS variables. Disabling this will reduce the maximum number of supported IDE controllers to 2 and place the variables in a memory area reserved for IBM ROM Basic (30:0h). You should always enable this option unless:
      1. You don't need to use IBM ROM Basic or any BIOS or software that requires that memory area.
      1. You have a Tandy 1000 with 640k or less RAM (see "kiB to steal from RAM" for a way around this problem).
      1. You really need the 1k of Conventional memory that "Full operating mode" requires.
  * kiB to steal from RAM [default=1]
> > This menu item will appear only when "Full operating mode" is enabled. Leave it at the default unless you need to enable "Full operating mode" on Tandy 1000 models with 640k or less RAM. Setting this to 33 (almost always enough) or 65 (always enough) will reserve the top of RAM to Tandy video circuitry in addition to the XTIDE Universal BIOS variables thus avoiding a conflict between the two.
  * IDE controllers [default=1 for XT builds, 2 for AT builds]
> > Number of IDE controllers to be searched by XTIDE Universal BIOS. The maximum is 4 if "Full operating mode" is enabled. Otherwise the maximum is 2.
  * Power Management [default=Disabled]
> > This menu item opens up a submenu where you can select the amount of time before idling harddrives should enter standby mode (i.e. stop spinning). This setting applies only to drives controlled by XTIDE Universal BIOS and requires that the drive(s) supports the Power Management feature set. Harddrives that do not support Power Management (only very old drives) will just keep spinning. Note that this option is not available if the BIOS has been built without MODULE\_FEATURE\_SETS.

### Menu items on "Boot settings" submenu ###
  * Display Mode [default=Default]
> > This setting allows you to force a display mode change before the boot menu is displayed. This setting will work even if the boot menu has been disabled and will leave the specified display mode set when booting to the OS. Forcing the display mode can be handy if you have a composite monitor (use 40 column modes for better readability) or a black&white VGA monitor (use 80 column black&white mode for better readability).
  * Number of Floppy Drives [default=Auto]
> > In some systems the number of floppy drives cannot be reliably autodetected. This setting allows you to specify it manually so all drives can be displayed on the boot menu.
  * Scan for Serial Devices [default=No]
> > When enabled, the BIOS will scan COM1-7 for a Serial Drive server at the end of standard drive detection. Even without this option enabled, holding down the ALT key at the end of drive detection will accomplish the same thing (useful for bootstrapping scenarios). The BIOS will display "Serial Master on COM Detect:" while it is scanning. See the [Serial Drive](SerialDrives.md) documentation for more information.
  * Default boot drive [default=80h]
> > Specifies what drive is booted by default unless user selects other drive using hotkeys or boot menu. The default of 80h means the first hard drive in the system. 00h means first floppy drive in the system if you want floppy drive A to be first.
  * Selection timeout [default=540]
> > Appears only if boot menu is included in the build.
> > Specifies the duration in timer ticks before the default boot drive is automatically selected. 1 tick = 54.9 ms so the default of 540 is about 30 seconds.


### Menu items on "xxx IDE Controller" submenus ###
  * Back to Configuration Menu
> > Moves back to "Configure XTIDE Universal BIOS" submenu.
  * Master Drive
  * Slave Drive
> > Opens submenu for Master/Slave Drive specific settings for this IDE Controller.
  * Device Type [default=XTIDE for XT builds, 16-bit for AT builds]
> > Following devices are supported:
    * 16-bit ISA/VLB/PCI IDE [for AT builds](default.md)
> > > 32-bit mode will be automatically enabled when supported VLB/PCI controller is detected.
    * 32-bit VLB/PCI IDE
> > > For those 32-bit controllers that do not require software support (PIO mode is set with jumpers). Can be used with all 32-bit controllers but PIO mode is 0 just like on 16-bit controllers.
    * 16-bit ISA IDE in 8-bit mode
> > > Allows to use 16-bit IDE controllers on XT systems. This will require drive that supports 8-bit transfers (CF card and Microdrives all support 8-bit mode).
    * XTIDE rev 1 [for XT builds](default.md)
    * XTIDE rev 2 or modded rev 1
> > > XTIDE with A0 and A3 address lines swapped.
    * XT-CF v2/v3/Lite in PIO mode
    * XT-CF v2 in DMA mode
    * XT-CF v2 in memory mode
    * JR-IDE/ISA
    * Serial port virtual device
> > > Note that a serial port controller must be the last configured IDE controller. XTIDECFG will automatically move any serial ports to the end of the list if needed. This is done so that serial floppy disks, if any are present, will be last on the list of drives detected.
  * Base (cmd block) address [default=300h for XT builds, 1F0h (Primary IDE) and 170h (Secondary IDE) for AT builds]

> > Command block (base port) address where the IDE Controller is located. JR-IDE/ISA does not use this setting.
  * Control block address [default=308h for XT builds, 3F0h/370h for AT builds]
> > Set to base port + 8h for XTIDE rev1, rev2 and Lo-tech XT-CF. Set to base port + 200h for standard IDE controllers. JR-IDE/ISA does not use this setting.
  * Enable interrupt [default=no]
> > Enables interrupt but it does not offer any benefit for MS-DOS. Do not enable unless you know you need it.
  * IRQ [default=14 for Primary IDE, 15 for Secondary IDE]
> > Appears only when MODULE\_IRQ is available.
> > IRQ channel to use for IDE controllers.
  * COM Port [default=COM1]
> > Appears only when serial port virtual device is selected.
  * Baud Rate [default=38.4K]
> > Appears only when serial port virtual device is selected.

### Menu items for "Master/Slave Drive" submenus ###
  * Back to IDE Controller Menu
  * Block Mode Transfers [default=Yes]
> > Block Mode Transfers will speed up the transfer rates. This should be left enabled but there is at least one old hard drive with buggy block mode support when interrupts are enabled (Quantum, maybe 100MB).
  * CHS Translation Method [default=Auto]
> > The NORMAL/LARGE/LBA selection seen on many BIOSes. Leave this to Auto unless you want this to be the same you are using on some other BIOS.
  * Internal Write Cache [default=Disabled]
> > This should be left disabled unless you know what you are doing! Improper use of write cache can cause data corruption.
  * User specified CHS [default=no]
> > Specify CHS parameters manually. This will force the drive to CHS addressing and EBIOS functions will be disabled. Specifying CHS manually makes the drive incompatible with other BIOSes unless they are specified to use the same CHS parameters.
  * User specified LBA [default=no]
> > Specify drive capacity manually (starting from 8.4 GB). All versions of MS-DOS 7.x (Windows 9x) seem to have compatibility problems with very large drives so you might need to reduce drive capacity. Use FreeDOS if you want to use full capacity of the drive.
  * Cylinders, Heads and Sectors per track
> > These will appear when "User specified CHS" is enabled. Maximum values of 16383 Cylinders, 16 Heads and 63 Sectors per track will provide a capacity of 7.8 GiB/8.4 GB, the maximum that MS-DOS 3.31 to 6.22 supports. Note that this will force CHS addressing so once formatted, there will be data corruption if you try to access the drive with systems using LBA addressing.
  * Millions of sectors
> > This will appear when "User specified LBA" is enabled. You can specify the drive capacity in millions of sectors. Note that MS-DOS 7.x (Windows 9x) or FreeDOS is required to access more than 7.8 GiB/8.4 GB.


---

# Hotkeys #

You will see Hotkeybar at the top of screen during drive detection. Hotkeys are available during that time and selected hotkeys will be displayed on the Hotkeybar.

Keys A to Z work as hotkeys for drives to select as boot device. Hotkeys have another benefit: they allow the installation of DOS from any floppy drive to any hard disk. For example if you want to install DOS from floppy drive B to Hard Drive D then first press D and then B. The last drive selected is always the drive to boot from.

F2 displays boot menu (available only if MODULE\_BOOT\_MENU is available).

F6 will search for virtual serial drives on COM ports 1-7 at the end of standard drive detection (available only if MODULE\_SERIAL is available).

F8 calls software interrupt 18h. This starts IBM ROM Basic, ROM DOS or displays an error message from the motherboard BIOS when there is no ROM to boot from.


## Drive swapping ##

DOS requires that it is loaded from the first floppy drive (00h) or the first hard disk (80h) in the system. XTIDE Universal BIOS translates drive numbers to make booting possible from any floppy drive or hard disk. Drive number translation is implemented with a simple swapping method: selected drive will be swapped with first drive and vice versa. For example drive 81h (Second hard drive) would be translated to 80h (First hard drive) and 80h would be translated to 81h. Drive swapping for floppy drives and hard disks are handled separately to make possible to install DOS from any floppy drive to any hard disk.


---

# Boot menu #

Using the boot menu is optional and it is not included in official 8 kiB builds. Boot menu does not offer any more functionality than hotkeys except to display drive information. Drive can be selected with Up and Down arrows. Home, End, PgUp and PgDn keys can speed up selection if there are many drives in the boot menu. Press Enter to boot from selected drive.

## Boot menu drive information ##

The boot menu can display a little bit of information about the drive:

  * Capacity
> > This shows the drive capacity. This is the same as reported by the drive unless you have specified CHS or LBA manually. Capacity is read from INT 13h AH=08h for drives not handled by XTIDE Universal BIOS.
  * Addr.
> > This shows the current addressing mode:
      * NORMAL is used for drives with 1024 or less cylinders (504 MiB / 528 MB and smaller drives). NORMAL is the fastest mode since no address translations are required.
      * LARGE is used for drives with 1025...8192 cylinders. LARGE addressing mode L-CHS parameters are generated with Revised Enhanced CHS calculation algorithm. LARGE addressing mode can use LBA if drive supports it.
      * LBA is used for drives with 8193 or more cylinders and LBA support. L-CHS parameters are generated with Assisted LBA algorithm.
  * Block
> > Shows the maximum number of sectors supported in a single multi-sector transfer. The larger the better. 1 means that block mode is disabled or not supported. CF cards usually supports block mode commands but do not allow blocks larger than 1 sector.
  * Bus
> > Shows the bus/device type configured in "Device Type" menu item on "xxx IDE Controller" submenu.
  * IRQ
> > Shows the IRQ channel if enabled.
  * Reset
> > Shows the status from drive initialization. This should always be zero. If it is something else, then something has gone wrong.


---

# Performance problems #

## MS-DOS DIR command takes a very long time ##
This is completely normal on systems with slow CPUs and large partitions. Calculating free space is simply a very slow process in such cases.

It was very rare to have partitions larger than 32 MiB on XT systems so there weren't long delays then. Now XTIDE and JR-IDE/ISA makes it possible to use very large modern drives on such slow systems. MS-DOS 3.31 allows partitions up to 512 MiB and MS-DOS 4.00 to 6.22 allows partitions up to 2 GiB. Those are enormous sizes for XT systems and the slow 8088 or even the V20 take some time to calculate the free space on FAT file systems.

It might be a good idea to use a small partition for OS and frequently used utilities and large partition(s) for games and less needed data. You should experiment with what size feels the best for the small partition. Please do let me know the results if you do some testing.

It is very likely that this same problem will occur if you decide to use MS-DOS 7.x (Windows 9x) or FreeDOS and a large FAT32 partition on a slow 386 or even 486.


## Smartdrive can slow down transfer rates ##
When smartdrive or other cache program is used, data is read from drive to RAM area used by the cache program. Then it is copied to the program RAM area. If same data is required again it is found from the cache. Reading from cache is a lot faster than reading from drive, especially when the drive is old.

Modern drives are a lot faster and they have very large internal caches and data prefetch abilities. Modern drives are so fast on old computers that the extra CPU usage required by caching programs slow down more than reading directly from drive, at least with slow CPUs and small caches.

Don't assume that disk caching makes things faster. Always test it first.


## Importance of Shadow RAM ##
Always enable Shadow RAM and ROM area caching if your systems supports them! They might speed up much more than you think. This is especially true on Pentium systems.

Pentium will fetch at least 8 bytes (since it has a 64-bit wide bus) before it can start to execute the instructions. Even if you have placed the ROM on a 16-bit ISA or 32-bit VLB or PCI card the ROM itself is only 8-bits wide. So the ROM must be read 8 times before the CPU can start executing instructions. And if those 8 times are read from 8 MHz ISA with wait states... Believe it or not, this can slow the transfer rates on a mighty Pentium to the level of fast XT systems.

So always enable Shadow RAM to copy the ROM to RAM to get full bus width and you might also want to enable cache for ROM areas to compensate for RAM latencies and slower clock rate. The Shadow RAM is the more important of the two.

You should be aware that you most likely need to disable Shadow RAM when you flash the EEPROM. Another thing to note is that JR-IDE/ISA does not work if Shadow RAM or ROM area caching is enabled. You wouldn't want to connect drives to an 8-bit bus on a 32-bit system anyway. You can use the JR-IDE/ISA if you just need the 512 kiB FLASH.

Here are some transfer rate comparisons using v2.0.0β1. Results are from [IOTEST by Michael B. Brutman](http://www.brutman.com/iotest.zip).

The test system is a 486DX4 100 MHz with a VLB Multi I/O card and a 6 GB Hitachi Microdrive. XTIDE Universal BIOS is configured for 16-bit transfers without support for that specific VLB IDE controller.
|Internal Cache|Shadow RAM|KB/s|
|:-------------|:---------|:---|
|Enabled       |Disabled  |1185.50|
|Enabled       |Enabled   |1911.37|
|Disabled      |Disabled  |1145.48|
|Disabled      |Enabled   |1851.30|


---

# IDE controllers on VLB and PCI bus #

16-bit ISA IDE controllers or more properly interface cards are basically very simple ISA to Parallel ATA adapters so they all perform alike. ISA is not fast enough for anything above PIO-0 transfer method (with a theoretical maximum of 3.3 MB/s).

VLB and PCI IDE controllers are more complex since they have an actual controller between bus and IDE drive. This controller can buffer the data so the CPU can read 32-bits at a time. Early VLB controllers are limited to PIO-2 but later VLB controllers and (all?) PCI controllers also support PIO modes 3 and 4. These later VLB multi I/O cards have two IDE connectors so you should use one of those even if you don't need the other IDE connector.

Unfortunately many of the controllers work only at PIO-0 by default. Some VLB multi I/O cards have jumpers to set transfer rates but most require controller specific programming to enable higher PIO modes. It is possible that your VLB multi I/O card don't offer any advantages over ISA multi I/O cards if your BIOS does not support the IDE controller on the VLB card. There are DOS drivers for many VLB IDE controllers so BIOS support isn't a necessity.

At the moment XTIDE Universal BIOS has native support for QDI Vision QD6500 and QD6580 VLB IDE controllers. The support is included in MODULE\_ADVANCED\_ATA that is included in official AT builds by default.


---

# Known problems with fixes (v2.0.0 beta 2) #

### Flashing sometimes fails on a Pentium system ###
Set page size to maximum supported and try to reflash few times. Eventually it should work. It is currently unknown why flash fails.

### FreeDOS Format.exe freezes ###
Known to happen with 0.90 dated 4-30-02 when using user defined LBA. Change FORMAT.EXE to newer. 0.91v dated 1-14-06 is known to work.


# Other known problems #
  * Flash utility hung the PC when saving settings on one occasion (maybe because the FDD entry point was via the BIOS just over-written?)
  * Detecting non-available drives takes a lot longer on XT systems than on AT systems. Both have same timeout values so it is unclear what causes it.


## Problems with Compact Flash cards and microdrives ##

CF cards and microdrives are IDE devices and should work as any hard disk. Unfortunately there are many CF cards and microdrives with limitations. Some of them only work as a master drive but not as a slave drive. Some of them requires MBR to be re-created before they can be used for booting.

The MBR can be re-created with FDISK using the /MBR switch. You can also use any low-level data wipe utility to clear a non-bootable MBR. The MBR will then be created automatically when partitioning the drive.

Some CF cards and microdrives do not work properly with IBM 5150/5160 when using XTIDE rev 1 or rev 2. Some of the symptoms are improperly displayed drive name on boot menu or the drive appears to work on some occasions and sometimes not. This is a hardware related problem and cannot be fixed by software. Wait for Lo-tech XT-CF to be available or use known working drive such as Hitachi 6 GB microdrive.


---

# Contact information #

[XTIDE Universal BIOS thread can be found at Vintage Computer Forums](http://www.vintage-computer.com/vcforum/showthread.php?17986-XTIDE-Universal-BIOS). I recommend to post there but you can also send email to aitotat (at) gmail.com. Another thread to take a look at is [XTIDE Universal BIOS v2.0.0 beta testing thread.](http://www.vintage-computer.com/vcforum/showthread.php?29749-XTIDE-Universal-BIOS-v2-0-0-beta-testing-thread)

When reporting bugs or other problems, please post the following information:
  * Computer specs (at least CPU and RAM but details about expansion cards and how they are configured might be useful)
  * Operating system and version (for example MS-DOS 6.22)
  * Hard disk(s) you are using with XTIDE Universal BIOS
  * Hard disk(s) not handled by XTIDE Universal BIOS (if any)
  * Reset status that boot menu shows if problem is related to specific drive