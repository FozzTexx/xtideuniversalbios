@rem = '--*-Perl-*--
@echo off
perl -x -S %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
#!perl
#
# Add checksum byte to ROM image
#
# Use a size of 0 to skip this script entirely (file is not modified)
#
# On Windows, this file can be renamed to a batch file and invoked directly (for example, "c:\>checksum file size")
#

#
# XTIDE Universal BIOS and Associated Tools
# Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
#

($ARGV[0] ne "" && $ARGV[1] ne "") || die "usage: checksum filename size\n";

$desiredSize = int($ARGV[1]);

if( $desiredSize == 0 )
{
	exit( 0 );
}

open FILE, "+<".$ARGV[0] || die "file not found\n";
binmode FILE;
$cs = 0;
$last = 0;
$bytes = 0;
while( ($n = read( FILE, $d, 1 )) != 0 )
{
	$cs = $cs + ord($d);
	$cs = $cs % 256;
	$bytes = $bytes + 1;
}
$oldBytes = $bytes;

if( $bytes > $desiredSize - 1 )
{
	die "ERROR: image is bigger than ".($desiredSize-1).": $bytes\n";
}

$fixzero = chr(0);

#
# Compatibility fix for 3Com 3C503 cards. They use 8 KB ROMs and return 8080h as the last word of the ROM.
#
if( $desiredSize == 8192 ) {
	if( $bytes < $desiredSize - 3 ) {
		while( $bytes < $desiredSize - 3 ) {
			print FILE $fixzero;
			$bytes++;
		}
		$fixl = ($cs == 0 ? 0 : 256 - $cs);
		$fix = chr($fixl).chr($cs);
		print FILE $fix;
		$bytes += 2;
	} else {
		print "Warning! ".$ARGV[0]." cannot be used on a 3Com 3C503 card!\n";
	}
}

while( $bytes < $desiredSize - 1 )
{
	print FILE $fixzero;
	$bytes++;
}

$fixl = ($cs == 0 ? 0 : 256 - $cs);
$fix = chr($fixl);
print FILE $fix;

close FILE;

open FILE, "<".$ARGV[0];
binmode FILE;
$cs = 0;
$newBytes = 0;
while( ($n = read( FILE, $d, 1 )) != 0 )
{
	$cs = $cs + ord($d);
	$cs = $cs % 256;
	$newBytes++;
}
$cs == 0 || die "Checksum verification failed\n";

print "checksum: ".$ARGV[0].": $oldBytes bytes before, $newBytes bytes after\n";

__DATA__
:endofperl
