**Table of Contents**


---

# Introduction #

Starting with version 2, the XTIDE Universal BIOS can emulate floppy and hard disks over a serial connection.  By doing so, aging hardware can be bootstrapped from a floppy image, or even run without a physical hard disk.  No special hardware is required, the BIOS can work with any standard COM port that is installed on the machine.  And with high speed COM ports, performance can approach the performance of vintage hard disks.

## System Requirements ##

To use this feature, you will need:

  * Client PC
    * Standard or High Speed COM Port
    * XTIDE Universal BIOS option ROM installed

  * Server PC
    * Standard or High Speed COM Port (USB add-ons serial ports work great)
    * Windows XP or later (In the future, support for additional platforms may be added)
    * Flat Disk Images of floppy disks or hard disks
    * Command line utility, SerDrive, included with the XTIDE Universal BIOS distribution

  * [Null Modem cable](http://en.wikipedia.org/wiki/Null_modem) between the two machines

## Getting Started ##

### 1. Connect ###

Connect the two machines via the serial cable.

### 2. Start the Server ###

Open a command prompt, and run the SerDrive utility on the server.  Switches are described below.  In its simplest form:
> ` C:\> SerDrive ImageFile.img `
If you do not already have an image, you can obtain boot floppies of FreeDOS at [www.fdos.org](http://www.fdos.org/bootdisks/) and possibly at the FreeDOS home page at [www.freedos.org](http://www.freedos.org) (although they tend to distribute FreeDOS as a CD-ROM image).  Be sure to use a newer version of FreeDOS Format, we have seen issues with version 0.90, that 0.91v corrected, and newer versions also have a debug switch for diagnosing problems.
SerDrive will use the first available COM port by default, at a speed of 9600 baud (which is reliable, but relatively slow, you will likely want to increase this for continued use).

### 3. Boot the Client ###

Boot the client computer.  **During drive detection, hold down the Alt key, and at the end of drive detection, the BIOS will display "Master at COM Detect".**  The BIOS will now scan the available COM ports on the client (COM 1-7), looking for a server.  If Hotkeys are enabled (MODULE\_HOTKEYS), pressing F6 will do the same thing.  And you can also configure the BIOS with XTIDECFG to always boot from the serial port (see below).

If a server is found, the floppy and/or hard disk emulated will appear in the boot menu for the BIOS.  You can now proceed as normal.

If you have problems, start by adding the `-v` switch to SerDrive and it will report on each connection request and sector transferred.  If that still doesn't work, you may want to try a basic serial communications program to see if you can send and receive characters across the serial port.  Depending on your version of Windows, it may include a serial communications program, or you could try a program such as [Kermit](http://www.kermitproject.org/).

# Performance #

Really, emulating a disk drive over a serial link?  That has to be pretty slow, right?

It depends.  Using high speed UARTs at a speed of 460K, performance is on par with floppy disk drives of the vintage era, without any of the seek time or interleave factors to slow it down (we're assuming the server PC is very fast and is caching heavily used sectors in memory).  With this level of throughput, serial drives are slower than a vintage hard disk, but not by much, and the system is completely usable.

And then there is the bootstrap scenario.  Imagine you find yourself with a PC without a working floppy disk drive, or the system floppy disk you want to boot is unreadable.  With only a standard COM port, common back in the day, you can still boot this machine and FDISK and/or FORMAT an attached hard disk.  It will take some time, no question about it, the top speed of many of these vintage COM ports was 38.4K.  But it will eventually boot.

Here's how various drives compare on performance, including the serial drives:

| | **5.25" DSDD Floppy** | **3.5" HD Floppy** | **Original IBM PC XT Hard Disk** | **38.4K Baud Serial Drive** | **460K Baud Serial Drive** |
|:|:----------------------|:-------------------|:---------------------------------|:----------------------------|:---------------------------|
| Theoretical Max Speed, Bytes per Second      | 31K                   | 62K                | 87K                              | 3.8K                        | 46K                        |
| Observed Speed, Bytes per Second             |                       | 42K                |                                  | 3.7K                        | 42K Read, 37K Write        |
| Time to Boot MS-DOS 3.3, Seconds             |                       | 14.5               |                                  | 30.5                        | 3.6                        |
| Time to Burst Read 274,688 bytes, Seconds    |                       | 6.6                |                                  | 72.1                        | 6.9                        |

So, how can boot time be so much faster with the serial connection than a floppy disk, yet burst read speed be worse?  There is a lot of overhead with seeking between tracks, waiting for the motor to spin the desired sector under the read head, etc. that goes away with the serial connection.  Even at a baud rate of 38.4K, 30 seconds is of course slow to boot, but completely reasonable for a boostrapping scenario.

Note that at high speed, write performance for serial drives is slightly worse than read performance - the BIOS code is optimized for read performance.

To help measure performance, SerDrive's `-v` switch with a value of 1 or higher will also display performance measurements for transfers of more than 100 sectors at a time.

Performance number Notes:
  * Serial drive theoretical max taken by dividing bit rate by 10, allowing for start and stop bits.  Wikibooks has a discussion of [Data Transmission Rates](http://en.wikibooks.org/wiki/Serial_Programming:RS-232_Connections#Data_Transmission_Rates) based on RS-232 serial communications overhead, in the Wikibook _[Serial Programming/RS-232 Connections](http://en.wikibooks.org/wiki/Serial_Programming:RS-232_Connection)_.
  * Floppy disk characteristics from Scott Mueller's _[Upgrading and Repairing PCs](http://books.google.com/books?id=E1p2FDL7P5QC&pg=PA649)_, 15th Anniversary Edition (2004), Page 649.
  * IBM PC XT Hard Disk performance as calculated based on maximum throughput and sector interleave by Steve Gibson in ["The Ways and Means of Faster Data Throughput"](http://books.google.com/books?id=CD8EAAAAMBAJ&pg=PA36), _InfoWorld_, March 7, 1988, Page 36.
  * Observed speeds and timings done on an original 4.77 MHz 8088 based IBM PC 5150.

# Configuring with XTIDECFG #

Holding down the Alt key is a bootstrapping feature, which is always available.  In addition, xtidecfg can be used to configure the BIOS to always look on a particular COM port for a server, or to automatically scan on each boot (as if the Alt key had been pressed).  See the [XTIDE V2.0.0 documentation for more details](Manual_V2_0_0.md).

Note that a serial port controller must be the last configured IDE controller.  Xtidecfg will move any serial ports to the end of the list if this is not already done.  This is done so that serial floppy disks, if any are present, will be last on the list of drives detected.

# SerDrive Command Line Arguments #

**` Usage: SerDrive [options] imagefile [[slave-options] slave-imagefile] `**

You can stop SerDrive by pressing Ctrl-C.  SerDrive is stateless, and flushes writes to the image files immediately.  You can start and stop the server at will, although this is not recommended.   If the server is stopped and a disk access is attempted by the client, that request will result in an error on the client.  Also, changing the image file without also rebooting the client may result in unexpected behavior and possible data loss.

**_Specify Disk Geometry:_ `-g` [cyl:head:sect]**

Geometry in cylinders, sectors per cylinder, and heads.  `-g` also implies CHS addressing mode (default is LBA28).

**_Create New Disk Image:_ `-n` [megabytes](megabytes.md)**

Create new disk with given size or use -g geometry.  Maximum size is 137438 MB (the LBA28 size limit).  Floppy images can also be created, such as "360K".  Default disk size is 32 MB disk, with a CHS geometry 65:16:63.

**_Emulator Pipe Mode:_ `-p` [pipename](pipename.md)**

Named Pipe mode for emulators.  Pipe name must begin with "\\", default is "\\.\pipe\xtide".

**_Specify COM Port:_ `-c` COMPortNumber**

COM Port to use (default is first found).  The usage message will also list the available COM ports on this system.

**_Specify Baud Rate:_ `-b` BaudRate**

Baud rate to use on the COM port.  If the client machine has a hardware rate multiplier (for high speed operation), then that will impact this setting:

| **Rate Multiplier** | **Available Baud Rates for SerDrive** |
|:--------------------|:--------------------------------------|
| None                |  2400,  4800,  9600,  28.8K,  57.6K, 115.2K |
| 2x                  | 4800,  9600, 19200,  57.6K, 115.2K, 230.4K |
| 4x                  | 9600, 19200, 38400, 115.2K, 230.4K, 460.8K |
| 8x                  | 19200, 38400, 115.2K, 230.4K, 460.8K, 921.6K |

And for completeness, 76.8K and 153.6K can also be set.  The default baud rate is 9600 (115.2K when used in named pipe mode).

Note that in Windows' Device Manager, a high speed COM port may still show that it's maximum speed is 128K baud.  Do not be alarmed, this setting has no impact on what SerDrive does with the Windows API, where the higher speeds are available.  No manual setup of the serial port is required before SerDrive runs.

Theoretically, and this is why the server supports it, 921.6K should be possible with a fast enough card and an 8x multiplier, hosted in a computer that can operate at least twice as fast as a 4.77Mhz 8088 machine.  I have only tested up to 460.8K with actual hardware.

**_Disable Operation Timeout:_ `-t`**

Disable timeout, useful for long delays when debugging.

**_Read Only Disk:_ `-r`**

Treat the disk as a Read Only disk, SerDrive will not allow writes.

**_Verbose:_ `-v` [level](level.md)**

Reporting level 1-6, with increasing information as the number increases.  This switch can be very useful for seeing the sector-by-sector traffic between the PC and the hard disk.

The `-v` switch with a value of 1 or higher will also display performance measurements for block transfers of more than 100 sectors.

**_ImageFiles:_ ImageFileName**

Finally, the image file name appears. Up to two image files can be used, each with their own settings for many of the switches above.

Floppy images may also be used.  Image size must be exactly the same size
as a 2.88MB, 1.44MB, 1.2MB, 720KB, 360KB, 320KB, 180KB, or 160KB disk.
Floppy images must be the last disks discovered by the BIOS, and only
two floppy drives are supported by the BIOS at a time.

# High Speed Operation #

Normal COM ports top out their speed somewhere between the reliable 9600 baud and the unreliable theoretical maximum of 115.2K baud.  This includes COM ports that are included on the motherboard of even modern PCs.  COM ports with FIFOs can usually achieve the 115.2K speed.  In addition, High Speed COM ports were introduced with a clock multiplier, resulting in top speeds of 230.4K and 460.8K.  Many USB COM ports on the market can achieve 500K or higher speeds.

The BIOS supports speeds up to 460.8K baud.  To achieve this speed, you will need:

  * COM port on the client machine capable of high speed operation.  Believe it or not, one can still buy new ISA High Speed COM ports that accomplish this, that can even be used in old 8-bit machines.  You are looking for serial cards with an "16550" (or better) UART chip, which includes a FIFO, and the ability to set a hardware rate multiplier, typically this is jumpers for 1x, 2x, and 4x.  Serial cards that have been tested:
    * [XTIDE rev2](http://www.vintage-computer.com/vcforum/showwiki.php?title=XTIDE+Rev2) has a high speed COM port installed for this purpose.
    * [StarTech ISA2S550](http://www.startech.com/Cards-Adapters/Serial-Cards-Adapters/2-Port-16550-Serial-ISA-Card~ISA2S550)
    * [Siig JJ-A40012](http://www.siig.com/i-o-expander-4s.html)
> The speed of the client PC should not be an issue. High speed operation has been succesfully used even on an original equipment IBM PC 5150.

  * COM port on the server machine capable of high speed operation.  Most motherboard based COM ports can NOT attain high speed.  However, most USB COM ports can attain high speed, check the product documentation if it states "Data Transfer Rate: 500kbps" or similar.  USB serial ports that have been tested with the BIOS:
    * [TRENDNet TU-S9](http://www.trendnet.com/products/proddetail.asp?prod=265_TU-S9&cat=32)
    * [IOGear GUC232A](http://www.iogear.com/product/GUC232A/), although beware that the specs only list up to 230Kbps, in limited practice it has worked up to 460K.

Care must be taken when configuring the serial connection - the clock multiplier is not detectable by the client PC.  With a 4x clock multiplier, the client PC should be set to 115.2K baud, while the matching server needs to be set to 460.8K baud.

Note that in Windows' Device Manager, a high speed COM port may still show that it's maximum speed is 128K baud.  Do not be alarmed, this setting has no impact on what SerDrive does with the Windows API, where the higher speeds are available.  No manual setup of the serial port is required before SerDrive runs.

Theoretically, 921.6K should be possible with a fast enough card and an 8x multiplier, hosted in a computer that can operate at least twice as fast as a 4.77Mhz 8088 machine.  I have only tested up to 460.8K with actual hardware, and ISA hardware with an 8x multiplier is hard to find.

# Disk Image Format #

Disk image files, at this time, are flat hard disk images.  Sectors are laid out on disk, starting with sector 0, and proceeding in LBA order (literally 512-byte sector 0, then 1, then 2, etc.).  No meta-data about the size of the disk or disk geometry is stored in the file. Also no compression of unused sectors is done.  SerDrive's "-n" switch can be used to create images of the proper size, with all sectors initialized to zeros.

In the future, support for additional disk image formats may be added.

## Disk Image Utilities ##

[WinImage](http://www.winimage.com/winimage.htm) is a good tool that can manipulate image files - it can view, inject, and extract files from a file system stored on the image.

Other possible tools include [DiskExplorer](http://hp.vector.co.jp/authors/VA013937/editdisk/index_e.html) and GNU has a set of tools called [Mtools](http://www.gnu.org/software/mtools), although I have not seen a good port of those to Win32.

## Emulators ##

Floppy and hard disk image files can be shared between the XTIDE Universal BIOS and other emulators, such as [Bochs](http://bochs.sourceforge.net).  One nice feature of this is that bootable images can be created and tested in an emulated environment, complete with multiple floppy and CD-ROM drives, and then the resulting image can be used with physical hardware through the BIOS.

Bochs was used in the development of the serial code, as its debugger offers control over the emulated system that is hard to accomplish on actual hardware.  You can run the XTIDE Universal BIOS in Bochs as an installed option ROM, and interface with Bochs' emulate IDE hard disks and serial ports.  To support serial ports, SerDrive's `-p` switch can be used to run over a Win32 named pipe instead of a physical COM port, and Bochs can be set to emulate a COM port over a named pipe.  In addition, it can be set to emulate a specific baud rate from the client (Bochs), using the standard `-b` switch.  The `-t` switch is useful to prevent the server from timing out on operations, if a breakpoint is hit in the BIOS code.