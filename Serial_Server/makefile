######################################################################
#
# Project:     XTIDE Universal BIOS, Serial Port Server
#
# File:        makefile
#
# Use with GNU Make and Microsoft Visual C++ 2010
#

CL = cl
CLFLAGS = /Ox

WIN32OBJS = build/win32.obj build/win32serial.obj build/checksum.obj build/serial.obj build/flatimage.obj build/process.obj build/image.obj

build/serserve.exe:	$(WIN32OBJS)
	$(CL) /Febuild/serserve.exe $(WIN32OBJS)

build/%.obj:	win32/%.cpp
	$(CL) /c $(CLFLAGS) $< /Fo$@

build/%.obj:	library/%.cpp
	$(CL) /c $(CLFLAGS) $< /Fo$@

$(WIN32OBJS):	library/library.h

build/checksum_test.exe:	library/checksum.cpp
	$(CL) /Febuild/checksum_test.exe /Ox library/checksum.cpp /Fobuild/checksum_test.obj -D CHECKSUM_TEST

clean:	
	del /q build\*.*

