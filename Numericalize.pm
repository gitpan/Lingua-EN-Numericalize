#!/usr/bin/perl

=head1 NAME

Lingua::EN::Numericalize - Replaces English descriptions of numbers with numerals

=cut

package Lingua::EN::Numericalize;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/&str2nbr/;
our $VERSION = substr q$Revision: 1.3 $, 10;

local $\ = $/;
our $debug = 0;
our $UK = 0;

=head1 SYNOPSIS

 use Lingua::EN::Numericalize;
 print str2nbr("one thounsand maniacs");

 $_ = "six hundred three-score and six";
 str2nbr();
 print;

 $Lingua::EN::Numericalize::UK = 1;
 print str2nbr("one billion");      # 1,000,000,000,000

=head1 DESCRIPTION

This module interpolates English descriptions of numbers in a given string with their numeric counterparts.  It supports both ordinal and cardinal numbers, negative numbers, and very large numbers.

The module exports a single function into the caller's namespace as follows:

=over

=item B<str2nbr [string = $_]>

This function receives an optional string (using $_ if none is passed) and converts all English text that describes a number into its numeric equivalent.  When called in a void context, the function sets $_ to the new value.

=back

The module's behaviour is affected by the following variables:

=over

=cut

sub str2nbr {
    my $s = lc(shift);
    local $_ if wantarray();
    
    $s =~ s/$_/$strrep{$_}/eeg for keys %strrep;

    my @ret;
    for (split /\b/, $s) {
        push(@ret, $_), next if /^\d+$/;
        push(@ret, $_), next if /[^A-Za-z]/;

        push(@ret, word2num());
        }

    # generate number sequences

    my $i = 0;
    while ($i < $#ret) {
        $ret[$i] = [ $ret[$i] ], $n = 1 if isnbr($ret[$i]);
        if (ref($ret[$i])) {
            my $next = $ret[$i + 1];
            push @{$ret[$i]}, $next if isnbr($next);
            splice(@ret, $i + 1, 1), next
                if isnbr($next) || isconj($next);
            }
        $i++;
        }

    # calculate sequences

    ref && ($_ = seq2int(@$_)) for @ret;
        
    $_ = join "", @ret;
    }

=item B<$Lingua::EN::Numericalize::UK>

This variable may be set to indicate that the UK meaning of C<billion> should be used.  By default, this module uses the American meaning of this word :( Please note that all the related larger numbers e.g. trillion, quadrillion, etc. assume the chosen behaviour as well.

=item B<$Lingua::EN::Numericalize::debug>

If set to true, the module outputs on standard error messages useful for debugging.

=back

=cut

# conjunctions are valid separators for text numbers

our @conj = ('and', 'of', '\s+', '-', ',');

our %strrep = (
    'milion' => "million",              # common mispelling
    '(\d)\s*,\s*(\d)' => q/"$1$2"/,     # commas in numbers ok to remove
	q/baker('?s)?(\s+)?dozen/ => "baker",  # colloquialism
    '(\d)(st|nd|rd|th)' => q/"$1"/,
    );

our %tokrep = (
    'th$'      => "",         # cardinals
    '(s?e)?s$' => "",         # pluralis
    'tie'      => "ty",       # four[tie]th
    );

our %suffix = (
    teen    => sub { 10 + shift },
    ty      => sub { 10 * shift },
    illiard => sub { 10 ** (9 + 6 * (shift() - 1)) },
    illion  => sub {
        my $k = shift;
        return 1e6 if $k == 1;
        my $n = $UK ? 6 * $k : 3 * ($k - 1);
        10 ** ($n + 6);
        },
    );

our %latin = (
    un       => 1,
    duo      => 2,
    tre      => 3,  tr      => 3,
    quattuor => 4,  quadr   => 4,
    quin     => 5,  quint   => 5,
    sex      => 6,  sext    => 6,
    septen   => 7,  sept    => 7,
    octo     => 8,  oct     => 8,
    novem    => 9,  non     => 9,
    dec      => 10,
	undec    => 11,
	duodec   => 12,
    tredec   => 13,
    quattuordec => 14,
    quindec  => 15,
    hex      => 16,
    vigint   => 20,  vig    => 20,
    trig     => 30,
    cent     => 100,
    );
    
our %word2num = (
	naught      => 0,
    first       => 1,
    second      => 2,
    third       => 3,
	zero        => 0,
	one         => 1,
	two         => 2,
	three       => 3,   thir    => 3,
	four        => 4,
	five        => 5,   fif     => 5,
	six         => 6,
	seven       => 7,
	eight       => 8,   eigh    => 8,
	nine        => 9,   nin     => 9,
	ten         => 10,
	eleven      => 11,
	twelve      => 12,	twelf   => 12,
	twen        => 2,
	hundred     => 100,
	thousand    => 1000,

    m => 1,     # nillion/milliard
    b => 2,     # billion
    
	googol      => 10 ** 100,
	googolplex  => 10 ** (10 ** 100),
	score       => 20,
	gros        => 12 * 12,     # gross
	dozen       => 12,
    baker       => 13,
	eleventyone => 111,
	eleventyfirst => 111,
    );

%word2num = (%word2num, %latin);

sub isnbr {
    ! /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ && return for @_;
    return 1;
    }

sub isconj {
    my $w = shift || $_;
    $w =~ /$_/ && return 1 for @conj;
    }
    
sub compound {
    my $w = shift || $_;
    
    my $ret = 0;
    for (keys %word2num) {
        $ret += $word2num{$_}, last if $w =~ s/$_$//;
        }
    return $ret, $w unless $ret && $w;

    my @ret = compound($w);
    $ret[0] += $ret;
    @ret;
    }

sub word2num {
    my $o = shift || $_;
    my $w = $o;

    $w =~ s/$_/$tokrep{$_}/g for keys %tokrep;

    # compounds e.g. fourtytwo

    my $ret; ($ret, $w) = compound($w);
    return $ret unless $w;

    for (keys %suffix) {
        next unless $w =~ s/$_$//;
        next unless defined $word2num{$w};
        my $f = $suffix{$_};
        return $f->($word2num{$w}) + $ret;
        }

    $o;
    }

sub seq2int {
    my @seq = @_;
    print "seq2int(): ", join "-", @seq if $debug;
    my ($i, $max) = (0) x 2;
    ($max < $seq[$_]) && ($max = $seq[$_], $i = $_) for 0 .. $#seq;
    if ($i == 0) {
        my $ret = 0;
        $ret += $_ for @seq;
        return $ret;
        }
    $seq[$i] * seq2int(@seq[0 .. $i - 1]) + seq2int(@seq[$i + 1 .. $#seq]);
    }

1;

__END__

=head1 NOTES

Scores are supported, e.g. "four score and ten", so are dozens, baker's dozens and grosses.

Various mispellings of numbers are understood.

While it handles googol correctly, googolplex is too large to fit in perl's standard scalar type, and "inf" will be returned.

=head1 TODO

=over

=item B<1)> would be nice to handle fractions

=item B<2)> spelled out number e.g. nine one one = 911 (not 11: 9+1+1)

=back

Any suggestions are welcome.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 ACKNOWLEDGEMENTS

This module was inspired by Joey Hess' B<Words2Nums> but is a complete rewrite with an entirely different internal approach.  It differs from his module in that it is smart enough to ignore strings it doesn't recognise, thus preempting the impossible requirement that the user first parse the string.  As an example, a string like C<One Thousand Maniacs> would fail if passed to Words2Nums (since it contains C<Maniacs>) and doing a split and passing each individual piece would yield C<1 1000 maniacs> instead of the desired C<1000 maniacs>.

=head1 SUPPORT

For help and thank you notes, e-mail the author directly.  To report a bug, submit a patch or add to our wishlist please visit the CPAN bug manager at: F<http://rt.cpan.org>

=head1 AVAILABILITY

The latest version of the tarball, RPM and SRPM may always be found at: F<http://perl.arix.com/>

=head1 LICENCE AND COPYRIGHT

This utility is free and distributed under GPL, the Gnu Public License.  A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.gnu.org/licenses/> to obtain a copy of this license.

$Id: Numericalize.pm,v 1.3 2003/02/04 03:07:48 ekkis Exp $

=cut
