#!/usr/bin/perl -w

use strict;

die("subsample.perl FILE_SCORE FILE_F FILE_E OUT") unless scalar(@ARGV) == 4;
my ($FILE_SCORE,$FILE_F,$FILE_E,$OUT) = @ARGV;

$FILE_E =~ /\.([^\.]+)$/;
my $ext_e = $1;
$FILE_F =~ /\.([^\.]+)$/;
my $ext_f = $1;

# collect word count per score
my %SCORE;
open(E,$FILE_E);
open(SCORE,$FILE_SCORE);
while(my $e = <E>) {
  chop($e);
  my $score = <SCORE>; chop($score);
  my $e_length = scalar split(/ /,$e);
  $SCORE{$score} += $e_length;
}
close(E);
close(SCORE);

# compute thresholds
my %THRESHOLD;
my $count = 0;
foreach my $score (sort {$b <=> $a} (keys %SCORE)) {
  $count += $SCORE{$score};
  $THRESHOLD{$score} = $count;
}
print $count."\n";

# find threshold cutoff values for specified sizes
my @SIZE = (1e6,5e6);
my %THRESHOLD_CUTOFF;
my $size = 0;
foreach my $score (sort {$b <=> $a} (keys %THRESHOLD)) {
  while ($THRESHOLD{$score} > $SIZE[$size]) {
    $THRESHOLD_CUTOFF{$SIZE[$size++]} = $score;
    last if $size == scalar(@SIZE);
  }
  last if $size == scalar(@SIZE);
}

# open files to store subsampled sets
my (%OUT_E,%OUT_F);
foreach my $size (@SIZE) {
  open $OUT_E{$size},"> $OUT.$size.$ext_e";
  open $OUT_F{$size},"> $OUT.$size.$ext_f";
}

# write out sentence pairs scoring over threshold
open(E,$FILE_E);
open(F,$FILE_F);
open(SCORE,$FILE_SCORE);
while(my $e = <E>) {
  chop($e);
  my $f = <F>; chop($f);
  my $score = <SCORE>; chop($score);
  my $e_length = scalar split(/ /,$e);
  foreach my $size (@SIZE) {
    my $cutoff = $THRESHOLD_CUTOFF{$size};
    if ($score >= $cutoff) {
      my $fh_e = $OUT_E{$size};
      my $fh_f = $OUT_F{$size};
      print $fh_e "$e\n";
      print $fh_f "$f\n";
    }
  }
}
close(SCORE);
close(F);
close(E);

