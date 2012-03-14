######################################################################
#
# Project:     XTIDE Universal BIOS, Serial Port Server
#
# File:        makefile
#
# Use with GNU Make and Microsoft Visual C++ 2010
#
# Also works with Open Watcom C/C++ Version 1.9
#

HEADERS = library/library.h win32/win32file.h win32/win32serial.h library/file.h library/flatimage.h

CL = cl
CLFLAGS = /Ox /DWIN32

WIN32OBJS = build/win32.obj build/checksum.obj build/serial.obj build/process.obj build/image.obj

build/serdrive.exe:	$(WIN32OBJS)
	@$(CL) /Febuild/serdrive.exe $(WIN32OBJS)

build/win32.obj:	win32/win32.cpp $(HEADERS)
	@$(CL) /c $(CLFLAGS) win32/win32.cpp /Fobuild/win32.obj

build/checksum.obj:	library/checksum.cpp $(HEADERS)
	@$(CL) /c $(CLFLAGS) library/checksum.cpp /Fobuild/checksum.obj

build/serial.obj:	library/serial.cpp $(HEADERS)
	@$(CL) /c $(CLFLAGS) library/serial.cpp /Fobuild/serial.obj

build/process.obj:	library/process.cpp $(HEADERS)
	@$(CL) /c $(CLFLAGS) library/process.cpp /Fobuild/process.obj

build/image.obj:	library/image.cpp $(HEADERS)
	@$(CL) /c $(CLFLAGS) library/image.cpp /Fobuild/image.obj


release:	build/serdrive.exe
	@echo Compressing with UPX...
	@upx -qq --ultra-brute build/serdrive.exe
	@echo Done!

clean:
	@del /q build\*.*


build/checksum_test.exe:	library/checksum.cpp
	@$(CL) /Febuild/checksum_test.exe /Ox library/checksum.cpp /Fobuild/checksum_test.obj -D CHECKSUM_TEST

