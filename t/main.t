#!/usr/bin/perl

use strict;
use Test;

our @tests;

BEGIN {
	open(F, "t/list") || die "list: $!";
	@tests = grep { chomp; ! /^#/ } <F>;
	plan tests => scalar @tests;
}

use Lingua::EN::Numericalize;

foreach (@tests) {
	my ($num, $text) = split '\t+', $_, 2;
	ok(str2nbr($text), $num);
    }
