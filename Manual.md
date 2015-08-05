**Table of Contents**


---

# Introduction #

XTIDE Universal BIOS is mainly used with [XTIDE controller](http://wiki.vintage-computer.com/index.php/XTIDE_project) to use modern IDE drives on PC/XT systems. XTIDE Universal BIOS supports 16- and 32-bit IDE controllers found in later ISA, VLB and PCI systems. Thus XTIDE Universal BIOS can be used to overcome 504 MiB hard disk size limit that many old BIOSes have.


## Features ##

Some of the features included in XTIDE Universal BIOS are...
  * Supports up to 5 IDE controllers (10 drives)
  * Accesses up to 8.4 GB hard disk space (BIOS CHS limit)
  * Block mode transfers
  * Hard disk autodetection
  * Autodetected CHS parameteres can be overridden to make drive appear smaller than it is
  * Boot menu for selecting any floppy drive or hard disk to boot from, including hard disks that are not handled by XTIDE Universal BIOS
  * Compact Flash and Microdrive support
  * Support for most 8-, 16-, and 32-bit IDE controllers
  * IRQ and polling operation modes
...and many more.


## Different builds ##

At the moment there are three different builds included in the XTIDE Universal BIOS zip file:
  * IDE\_XT.BIN (XT build)
> > XT build uses only instructions supported by 8086/8088 making it the only build that can be used on any PC, including the original IBM PC model 5150.
  * IDE\_XTP.BIN (XT+ build)
> > XT+ build has the same features as the XT build but XT+ build uses instructions introduced in 80186/80188. Those instructions are supported by all later x86 CPUs, including NEC V20/V30. 8-bit transfers rates will be better thanks to INS and OUTS instructions.
  * IDE\_AT.BIN (AT build)
> > AT build is meant for all AT class machines (16-bit or 32-bit bus). AT build supports OS hooks to allow operating system to do some processing while drive seeks the requested data. By default, the AT build is configured to full mode to take advantage of all the features the XTIDE Universal BIOS offers.


---


# Installing XTIDE Universal BIOS #

## Hardware supporting XTIDE Universal BIOS ROM ##

The most convenient way to use XTIDE Universal BIOS is to use [XTIDE card](http://wiki.vintage-computer.com/index.php/XTIDE_project). It can be used on any PC with free 8-bit ISA slot. You might not want to connect any drives to it in 16- or 32-bit systems since 8-bit transfer will be very slow. Using XTIDE card allows EEPROM flashing so it is really easy to update XTIDE Universal BIOS.

Another option is to use any card with free ROM socket for 8 kiB or larger ROMs. Official XTIDE builds are meant for 8 kiB ROMs but you can burn it on larger ROM if you append enough zeroes to the end (only append zeroes so checksum does not change). Many network cards have unused ROM sockets but there are also few multi I/O cards and IDE controllers with ROM sockets.

You don't need EPROM/EEPROM programmer if you already have XTIDE card. XTIDE card can be used to flash additional EEPROMs (2864) that can be moved to EPROM (2764) sockets.


## Configuring and flashing BIOS ##

XTIDE Universal BIOS comes with DOS utility called idecfg.com. It configures XTIDE Universal BIOS and also works as a generic EEPROM flasher supporting EEPROM sizes up to 16 kiB. Idecfg.com allows saving changes to BIOS images so that they can be programmed with other programming software or device.


## Other things to know ##

CTRL can be held down to skip XTIDE Universal BIOS initialization. Only drive detection will be skipped when late initialization is used.


---


# Using IDECFG.COM (XTIDE Universal BIOS configuration and flashing program) #

Idecfg.com is intended to be user friendly. At the bottom of the screen appears quick information for each menu item. It can be hidden with F2 to make menu navigation faster on XT systems. Pressing F1 displays more detailed help for menu item. Sometimes the help is the same as the quick information but not always. Up, Down, PgUp, PgDn, Home and End keys are used for menu navigation. Enter selects menuitem and Esc resumes to previous menu.

Some menu items appear only when needed to make configuring easier.


## Menuitems on main menu ##
  * Exit to DOS
> > This menu item exits to DOS but allows user to save any unsaved changes.
  * Load BIOS from file
> > Loads any file with .BIN extension to be flashed.
  * Load BIOS from EEPROM
> > This menu item appears only when supported version of XTIDE Universal BIOS is detected. It loads the BIOS from EEPROM to be reconfigured.
  * Load old settings from EEPROM
> > This menu item appears only when supported version of XTIDE Universal BIOS is detected and same or another supported version is loaded to be configured. It loads the old settings so that the new version does not need to be reconfigured when updating XTIDE Universal BIOS to new version.
  * Configure XTIDE Universal BIOS
> > All XTIDE Universal BIOS settings can be found and configured from this sub menu.
  * Flash EEPROM
> > Settings for EEPROM flashing.


## Menuitems on Configure XTIDE Universal BIOS submenu ##
  * Back to previous menu
> > Resumes back to main menu.
  * Primary IDE Controller
  * Secondary IDE Controller
  * Tertiary IDE Controller
  * Quaternary IDE Controller
  * Quinary IDE Controller
> > IDE Controller menu items appear based on selected number of IDE controllers.
  * Boot menu settings
> > Opens sub menu for configuring boot menu. This menu item appears only when Boot loader type is set to Menu.
  * Late initialization
> > Normally expansion card BIOSes are initialized before POST completes. Some (older) systems initialize expansion card BIOSes before they have initialized themselves. This might cause problems since XTIDE Universal BIOS requires some main BIOS functions for drive detection. This problem can be fixed by using late initialization to detect drives on boot loader. Late initialization requires that XTIDE Universal BIOS is the last BIOS that installs INT 19h handler. Make sure that XTIDE ROM is configured to highest address if you have other storage device controllers present.
  * Maximize disk size
> > Old BIOSes reserve diagnostic cylinder (landing zone cylinder for MFM drives) that is not used. Later BIOSes do not reserve it to allow more data to be stored. Do not maximize disk size if you need to move the drive between XTIDE Universal BIOS controlled systems and systems with cylinder reserving BIOSes.
  * Full operating mode
> > Full mode supports up to 5 IDE controllers (10 drives). Full mode reserves a bit of RAM from top of base memory. This makes possible to use ROM Basic and software that requires top of interrupt vectors where XTIDE Universal BIOS parameters would be stored in lite mode. Lite mode supports only one IDE controller (2 drives) and stores parameters to top of interrupt vectors (30:0h) so no base RAM needs to be reserved. Lite mode cannot be used if some software requires top of interrupt vectors. Usually this is not a problem since only IBM ROM Basic uses them. Tandy 1000 models with 640 kiB or less memory need to use lite mode since top of base RAM gets dynamically reserved by video hardware. This happens only with Tandy integrated video controller, not with expansion graphics cards. It is possible to use full mode if reserving RAM for video memory + what is required for XTIDE Universal BIOS. This would mean 129 kiB but most software should work with 65 kiB reserved.
  * kiB to steal from RAM
> > Parameters for detected hard disks must be stored somewhere. In full mode they are stored to top of base RAM. At the moment 1 kiB is always enough but you might want to steal more if you want to use full mode with Tandy 1000. This menu item appears only when full operating mode is enabled.
  * Number of IDE controllers
> > Number of IDE controllers handled by XTIDE Universal BIOS. This menu item appears only when full operating mode is enabled.


## Menuitems on IDE Controller submenus ##
  * Back to previous menu
> > Resumes back to Configure XTIDE Universal BIOS submenu.
  * Master drive
  * Slave drive
> > Drive specific settings for master and slave drives.
  * Bus type
    * 8-bit dual port (XTIDE)
> > > 8-bit ISA controllers with two data ports. This is what the XTIDE card uses.
    * 8-bit single port
> > > 8-bit ISA controllers with one data port.
    * 16-bit
> > > ISA (16-bit) but it also works on VLB and PCI controllers.
    * 32-bit generic
> > > Generic 32-bit I/O for VLB and PCI controllers.
  * Base (cmd block) address

> > IDE controller command block address is the usual address mentioned for IDE controllers. By default the primary IDE controller uses port 1F0h and secondary controller uses port 170h. XTIDE card uses port 300h by default.
  * Control block address
> > IDE controller control block address is normally command block address + 200h. For XTIDE card the control block registers are mapped right after command block registers so use command block address + 8h for XTIDE card.
  * Enable interrupt
> > IDE controller can use interrupts to signal when it is ready to transfer data. This makes possible to do other tasks while waiting drive to be ready. That is not useful in MS-DOS but using interrupts frees the bus for any DMA transfers. Polling mode is used when interrupts are disabled. Polling usually gives a little better access times since interrupt handling requires extra processing. There can be some compatibility issues with some old drives when polling is used with block mode transfers.
  * IRQ
> > IRQ channel to use. All controllers managed by XTIDE Universal BIOS can use the same IRQ when MS-DOS is used. Other operating systems are likely to require different interrupts for each controller. This menu item appears only when interrupts are enabled.


## Menuitems on Master and Slave drive submenus ##
  * Block mode transfers
> > Block mode will speed up transfers since multiple sectors can be transferred before waiting next data request. Normally block mode should always be kept enabled but there is at least one drive with buggy block mode implementation.
  * User specified CHS
> > Specify (P-)CHS parameters manually instead of autodetecting them. This can be used to limit drive size for old operating systems that do not support large hard disks. Limiting cylinders will work for all drives but drives may not accept all values for heads and sectors per track.
  * Cylinders
  * Heads
  * Sectors per track
> > Number of user specified P-CHS cylinders, heads and sectors per track. These menu items appear only when user specified CHS is enabled.


## Menuitems on Boot menu settings submenu ##
  * Back to previous menu
> > Resumes back to XTIDE Universal BIOS configuration menu.
  * Default boot drive
> > Drive to be set selected by default when Boot Menu is displayed.
  * Display drive info
> > Boot Menu can display some details about the drives in system. Reading this data might be slow on XTs so you might want to hide drive information.
  * Display ROM boot
> > Some old systems have Basic or DOS in ROM. Since most systems don't have either, ROM Boot setting is disabled by default. Enable it if you have use for it.
  * Maximum height
> > Boot Menu maximum height in characters.
  * Min floppy drive count
> > Detecting correct number of floppy drives might fail when using floppy controller with it's own BIOS. Minimum number of floppy drives can be specified to force non-detected drives to appear on boot menu.
  * Selection timeout
> > Boot Menu selection timeout in seconds. When time goes to zero, currently selected drive will be booted automatically. Timeout can be disabled by setting this to 0.
  * Swap boot drive numbers
> > Some old operating systems (DOS) can only boot from Floppy Drive A (00h) or first Hard Disk (80h, usually drive C). Drive Translation can be used to modify drive numbers so that selected drive will be mapped to 00h or 80h so that it can be booted.
  * Boot loader type
    * Boot menu
> > > Boot menu where user can select drive to boot from.
    * Simple boot loader
> > > Typical A, C, INT 18h boot order.
    * System boot loader
> > > Uses main BIOS boot loader or boot loader provided by some other BIOS. System boot loader works only when late initialization is disabled since late initialization is done on a boot loader.


## Settings for Flash EEPROM submenu ##
  * Back to previous menu

> > Resumes to main menu.
  * Start flashing
> > Writes (configured) BIOS to EEPROM.
  * SDP command
    * None
> > > Do not use Software Data Protection. Meant for EEPROMs that do not support SDP.
    * Enable
> > > Write protects the EEPROM after flashing. Software Data Protection should always be enabled if EEPROM supports it.
    * Disable
> > > Disables Software Data Protection after flashing.
  * EEPROM address

> > Address (segment) where EEPROM is located.
  * Page size
> > Larger page size will improve write performance but not all EEPROMs support large pages or page writing at all. Byte writing mode will be used when page size is set to 1. Byte writing mode is supported by every EEPROM. Large pages cannot be flashed with slow CPUs.
  * Generate checksum byte
> > PC BIOSes require checksum byte to the end of expansion card BIOS ROMs. Checksum generation can be disabled so any type of binaries can be flashed.


---


# Boot menu #

Using boot menu is optional. Boot menu allows to boot from any floppy or hard disk drive. Drive can be selected with Up and Down arrows. Home, End, PgUp and PgDn keys can speed up selection if there are many drives in the boot menu. Press Enter to boot from selected drive.


## Drive swapping ##

DOS requires that it is loaded from first floppy drive (00h) or first hard disk (80h) in the system. XTIDE Universal BIOS can translate drive numbers to make booting possible from any floppy drive or hard disk. Drive number translation is implemented with simple swapping method: selected drive will be swapped with first drive and vice versa. For example drive 82h on boot menu would be translated to 80h and 80h would be translated to 82h. Drive swapping for floppy drives and hard disks are handled separately so it is possible to install DOS from any floppy drive to any hard disk. Drive number translation can be disabled with idecfg.com.


## Boot menu hotkeys ##

Keys A to Z work as a hotkeys for boot menu drives. Hotkeys have another benefit: they allow to install DOS from any floppy drive to any hard disk. Select hard disk from menu but do not press Enter. Press any floppy drive hotkey instead to boot from floppy while maintaining selected hard disk translation.


## Boot menu drive information ##

Boot menu can display a little bit information about the drive. Drive information can be disabled with idecfg.com.

  * Drive capacity
> > Boot menu displays drive type for floppy drives. The type is read from BIOS and it is the same you usually set in CMOS setup. XT systems do not support the BIOS function to return drive type so 5.25" or 3.5" DD is displayed. For foreign hard disks (hard disks not handled by XTIDE Universal BIOS) the boot menu displays capacity calculated from CHS-parameters returned by BIOS function INT 13h, AH=8h. It is the same capacity that MS-DOS 6.xx and older versions see. Same CHS-capacity is displayed for hard disks handled by XTIDE Universal BIOS. In addition to the CHS capacity, the boot menu will display another size that is the full size of the hard disk.
  * Drive configuration information is displayed for XTIDE Universal BIOS controlled drives. Information includes:
    * Addressing (Addr.)
> > > This can be L-CHS, P-CHS, LBA28 or LBA48. CHS addressing is the old type of addressing method where cylinder, head and sector numbers will be handled separately. Original PC BIOS functions are designed for CHS addressing with maximum  hard disk size being 7.8 GiB (8.4 GB). LBA addressing is modern addressing method where every sector has its own address. There are no cylinders or heads anymore. Enhanced BIOS functions were introduced for LBA drives but they are not supported before Windows 95 (DOS 7). These EBIOS function are not yet supported by XTIDE Universal BIOS. CHS address must be translated to LBA address when using old CHS BIOS functions with LBA addressing.
      * L-CHS (known as NORMAL on many old BIOSes) is used for drives <= 504 MiB that can accept the CHS parameters without translation. That makes L-CHS the fastest addressing method.
      * P-CHS (known as LARGE on many old BIOSes) is used for drives from 504 MiB up to 7.8 GiB. This is a bit slower than L-CHS since simple translation is required to make BIOS L-CHS parameters compatible with IDE P-CHS parameters.
      * LBA28 (28-bit address) allows drive sizes up to 128 GiB (137 GB) but maximum accessible size is 7.8 GiB when old BIOS functions are used. L-CHS to LBA translation is more complex and slower than L-CHS to P-CHS conversion.
      * LBA48 (48-bit address) work just like LBA28 but with 20 more address bits. This makes possible to use drives with over 128 GiB capacity.
    * Block mode (Block)
> > > Block size in sectors for block mode transfers. XTIDE Universal BIOS always uses largest supported block size. Block mode is disabled or not supported if this is 1.
    * Bus type (Bus)
> > > Displays the bus type that has been selected with idecfg.com.
    * IRQ
> > > Displays IRQ channel if IRQ has been enabled.
    * Reset
> > > Displays status information from drive reset and initialization. This should always be 00h. Anything else would indicate some sort of error. Let me know if you see something other than 00h.


---


# IDE controllers on VLB and PCI bus #

16-bit ISA IDE controllers are basically very simple ISA to PATA adapters so they all perform alike. ISA is not fast enough for anything above PIO-0 transfer method (with theoretical maximum of 3.3 MB/s).

VLB and PCI IDE controllers are much more complex since they have an actual controller between bus and IDE drive. This controller can buffer words so CPU can read 32-bits at a time. Later VLB and (all?) PCI controller also offer flow control so they can support PIO modes 3 and 4. Early VLB controller are limited to PIO-2. Later VLB multi I/O cards have two IDE connectors so you should use one of those even if you don't need the other IDE connector.

Unfortunately many of the controllers work only at PIO-0 by default. Some VLB multi I/O cards have jumpers to set transfer rates but most require controller specific programming to enable higher PIO modes. It is possible that your VLB multi I/O card don't offer any advantages over ISA multi I/O cards if your BIOS does not support the IDE controller on the VLB card. There are DOS drivers for many VLB IDE controllers so BIOS support isn't necessity.

XTIDE Universal BIOS does not support any specific VLB controllers at the moment. I'm planning to add support for Vision QD6580 controller soon.


---


# Known problems #

## Known bugs in XTIDE Universal BIOS ##
  * There are some compatibility problems with SCSI BIOSes.


## Problems with Compact Flash cards and microdrives ##

CF cards and microdrives are IDE devices and should work as any hard disk. Unfortunately there are many CF cards and microdrives with limitations. Some of them only work as a master drive and not as a slave drive. Some of them requires MBR to be re-created before they can be booted. Avoid CF cards without speed ratings. They are too slow to be used as a hard disks.

MBR can be re-created with FDISK /MBR switch. You can also use any low-level data wipe utility to clear non-bootable MBR. MBR will then be created automatically when partitioning the drive.

[Drive compatibility list can be found here](http://code.google.com/p/xtideuniversalbios/wiki/DriveCompatibility).


# Contact information #

[XTIDE Universal BIOS thread can be found at Vintage Computer Forums](http://www.vintage-computer.com/vcforum/showthread.php?17986-XTIDE-Universal-BIOS). I recommend to post there but you can also send email to aitotat (at) gmail.com.

When reporting bugs or other problems, please post the following information:
  * Computer specs (at least CPU and RAM but details about expansion cards and how they are configured might be useful)
  * Operating system and version (for example MS-DOS 6.22)
  * Hard disk(s) you are using with XTIDE Universal BIOS
  * Hard disk(s) not handled by XTIDE Universal BIOS (if any)
  * Reset status that boot menu shows if problem is related to specific drive