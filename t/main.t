#!/usr/bin/perl

use strict;
use Test;

our @tests;

BEGIN {
	open(F, "t/list") || die "list: $!";
	@tests = grep { chomp; ! /^#/ && ! /^\s*$/ } <F>;
	plan tests => scalar @tests;
}

use Lingua::EN::Numericalize;

foreach (@tests) {
	my ($num, $text) = split '\s*=\s*';
	ok(str2nbr($text), $num) || print STDERR " > $text\n";
    }
