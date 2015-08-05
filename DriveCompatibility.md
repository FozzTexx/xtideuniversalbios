

Note that compatibility problems are usually drive limitations and not XTIDE Universal BIOS issues.

# Compactflash cards #
| **CF card** | **Capacity** | **Speed rating** | **Works as slave** | **MBR must be rewritten** | **Comments** |
|:------------|:-------------|:-----------------|:-------------------|:--------------------------|:-------------|
| _Apacer Photo Steno_ | 64 MB        | none             | yes                | yes                       |              |
| _Apacer Photo Steno_ | 256 MB       | none             | yes                | yes                       |              |
| Apacer Photo Steno II Pro | 256 MB       | 100x             | yes                | no                        |              |
| _Apacer Photo Steno III_ | 512 MB       | 88x              | no                 | no                        |              |


---


# Microdrives #
| **Microdrive** | **Model** | **Capacity** | **Works as slave** | **MBR must be rewritten** | **Comments** |
|:---------------|:----------|:-------------|:-------------------|:--------------------------|:-------------|
| Hitachi        | HMS360606D5CF00 | 6 GB         | yes                | no                        |              |
| _Magicstor_    | GS10040A-11 | 4 GB         | no                 | yes                       | Slow seek times |
| _Seagate ST1.2 Drive_ | ST64022CF | 4 GB         | no                 | no                        |              |


---


# Hard disks #
| **Hard disk** | **Model** | **Capacity** | **Comments** |
|:--------------|:----------|:-------------|:-------------|
| _Quantum ProDrive LPS_ | 340AT     | 340 MB       | Does not properly support block mode transfers when interrupts are disabled. |


---


# CF-to-IDE adapter compatibility in 8-bit mode on 16-bit controllers #
Not all CF adapters can be used in 8-bit mode. Tests have been done with 40- and 80-pin cables with same results. All the tested adapters work when used in standard 16-bit mode.

## CF-IDE40 HX-08.03.06 (A in the picture) ##
| **System** | **Controller** | **Drive** | **Result** |
|:-----------|:---------------|:----------|:-----------|
| 8 MHz Turbo Board (XT clone) | MG-863-J1 Super IDE I/O Card (1 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | No problems |
| 8 MHz Turbo Board (XT clone) | IDE-PLUS-V4L (2 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | No problems |
| 8 MHz Turbo Board (XT clone) | JGBPRIME2C Super I/O (3 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | No problems |
| 8 MHz Turbo Board (XT clone) | Sound Blaster 16 (CT2290) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | No problems (tested only with 40-pin cable) |

## CF-IDE40 V.E0 (B in the picture) ##
| **System** | **Controller** | **Drive** | **Result** |
|:-----------|:---------------|:----------|:-----------|
| 8 MHz Turbo Board (XT clone) | MG-863-J1 Super IDE I/O Card (1 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | Does not POST |
| 8 MHz Turbo Board (XT clone) | IDE-PLUS-V4L (2 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | Does not POST |
| 8 MHz Turbo Board (XT clone) | JGBPRIME2C Super I/O (3 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | Does not POST |

## CF-IDE40 Adapter V.A1 (C in the picture) ##
| **System** | **Controller** | **Drive** | **Result** |
|:-----------|:---------------|:----------|:-----------|
| 8 MHz Turbo Board (XT clone) | MG-863-J1 Super IDE I/O Card (1 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | Does not POST |
| 8 MHz Turbo Board (XT clone) | IDE-PLUS-V4L (2 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | No problems |
| 8 MHz Turbo Board (XT clone) | JGBPRIME2C Super I/O (3 in the picture) | Hitachi 6 GB Microdrive (HMS360606D5CF00) | Does not POST |

![https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/CfAdapters.jpg](https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/CfAdapters.jpg)
![https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/MultiIoCards.jpg](https://xtideuniversalbios.googlecode.com/svn/wiki/pictures/MultiIoCards.jpg)