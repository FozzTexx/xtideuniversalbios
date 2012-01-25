######################################################################
#
# Project:     XTIDE Universal BIOS, Serial Port Server
#
# File:        makefile
#
# Use with GNU Make and Microsoft Visual C++ 2010
#

CL = cl
CLFLAGS = /Ox /DWIN32

WIN32OBJS = build/win32.obj build/checksum.obj build/serial.obj build/process.obj build/image.obj

build/serdrive.exe:	$(WIN32OBJS)
	$(CL) /Febuild/serdrive.exe $(WIN32OBJS)

build/%.obj:	win32/%.cpp
	$(CL) /c $(CLFLAGS) $< /Fo$@

build/%.obj:	library/%.cpp
	$(CL) /c $(CLFLAGS) $< /Fo$@

$(WIN32OBJS):	library/library.h win32/win32file.h win32/win32serial.h library/file.h library/flatimage.h

build/checksum_test.exe:	library/checksum.cpp
	$(CL) /Febuild/checksum_test.exe /Ox library/checksum.cpp /Fobuild/checksum_test.obj -D CHECKSUM_TEST

clean:	
	del /q build\*.*

