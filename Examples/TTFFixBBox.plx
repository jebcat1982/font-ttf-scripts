#! /usr/bin/perl

use strict;
use Font::TTF::Font;
use Getopt::Std;

our ($VERSION, $opt_v);

getopts('v');

$VERSION = '0.1'; # original 

unless (defined $ARGV[0])
{
    die <<"EOT";

    TTFFixBBox [-v] <infile> [<outfile>]

Re-calculates bounding boxes for all glyphs in a font. 
if <outfile> is provided, rewrite corrected font.  Options:

    -v verbose output to stdout

Version $VERSION

EOT
}



my @metrics = (qw (xMin yMin xMax yMax));
my $count = 0;

my $f = Font::TTF::Font->open($ARGV[0]) || die "Cannot open TrueType font '$ARGV[0]' for reading.\n";

$f->{'glyf'}->read;     # We're gonna modify the font, so read glyf table!
my $l = $f->{'loca'};

my @before;  # bounding boxes before update.

# Build a list of original bbox values:

$l->glyphs_do ( 
    sub {
        my ($g, $gid) = @_;
        $g->read_dat;
        $before[$gid] = join(',', @{$g}{@metrics});   # Aren't slices fun!
    }
);

# Also record the font-wide bounding box from head table:
my $oldfontbbox = join(',', @{$f->{'head'}}{@metrics});

# Update all bboxes the easy way:
$f->{'head'}->dirty;
$f->{'head'}->update;


# Find differences:
$l->glyphs_do ( 
    sub {
        my ($g, $gid) = @_;
        my $after = join(',', @{$g}{@metrics});
        if ($before[$gid] ne $after) {
            $count++;
            print "glyph $gid before: ($before[$gid]), after: ($after)\n" if $opt_v;
        }
    }
);

my $newfontbbox = join(',', @{$f->{'head'}}{@metrics});
if ($oldfontbbox ne $newfontbbox) {
    print "font: before: ($oldfontbbox), after: ($newfontbbox)\n" if $opt_v;
    $count++;
}
    
print "NB: all bounding boxes given as (", join(',', @metrics), ")\n" if $opt_v;
print "$count bounding box ", ($count == 1 ? "difference" : "differences"), ($ARGV[1] ? " fixed.\n" : " found.\n"); 

$f->out($ARGV[1]) if $ARGV[1];
