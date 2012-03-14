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
