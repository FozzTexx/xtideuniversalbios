#
# Looks for unused entry points, to aid in discovering dead code that can be removed
#
# Usage: unused.pl listing unused.asm
#
# where: listing is the normal listing from assembly
#        unused.asm is assembled with the -E nasm flag
#
# Annotations can be placed in the source to eliminate false positives:
#   a) if a label can be fallen into, place "; fall through to <label>" above the label
#   b) "; unused entrypoint ok" can be placed on the same line with the label
#   c) "; jump table entrypoint" can be placed on the same line with the label
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

print "::".$ARGV[0]."::".$ARGV[1]."::\n";

open( LST, "<", $ARGV[0] ) || die "cannot open listing: ".$ARGV[0];
open( UNUSED, "<", $ARGV[1] ) || die "cannot open unused.asm: ".$ARGV[1];

while(<LST>)
{
	if( /fall\s+(-?through\s+)?(to\s+)?([a-z0-9_]+)/i )
	{
		$ok{ $3 } = 1;
	}
	if( /unused\s+entrypoint\s+ok/i && /^\s*\d+\s+\<\d\>\s([a-z0-9_]+)\:/i )
	{
		$ok{ $1 } = 1;
	}
	if( /jump\s*table\s+entrypoint/i && /^\s*\d+\s+\<\d\>\s([a-z0-9_]+)\:/i )
	{
		$ok{ $1 } = 1;
	}
}

while(<UNUSED>)
{
	if( /^([a-z0-9_]+\:)?\s+db\s+(.*)$/i ||
        /^([a-z0-9_]+\:)?\s+dw\s+(.*)$/i ||
        /^([a-z0-9_]+\:)?\s+mov\s+(.*)$/i ||
		/^([a-z0-9_]+\:)?\s+call\s+(.*)$/i ||
		/^([a-z0-9_]+\:)?\s+push\s+(.*)$/i ||
        /^([a-z0-9_]+\:)?\s+j[a-z]?[a-z]?[a-z]?[a-z]?[a-z]?\s+(.*)$/i ||
		/^([a-z0-9_]+)?\s+equ\s+(.*)$/i )
	{
		$rem = $2;
		@words = split( /([a-z0-9_]+)/i, $_ );
		for( $t = 0; $t <= $#words; $t++ )
		{
			$jumptable{ $words[$t] } = 1;
		}
	}
	if( !(/^g_sz/) && /^([a-z0-9_]+)\:/i )
	{
		push( @definition, $1 );
	}
}

$results = 0;
for( $t = 0; $t <= $#definition; $t++ )
{
	$d = $definition[$t];
	if( !$ok{$d} && !$jumptable{$d} )
	{
		print $definition[$t]."\n";
		$results++;
	}
}

print ">>>> Unused Count: ".$results."\n";
