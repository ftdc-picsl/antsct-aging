#!/usr/bin/perl -w
#
# Wrapper script, just figures out if longitudinal and then runs
# the appropriate script.

use strict;
use Getopt::Long;

my $runLongitudinal = 0;

if ($#ARGV < 0) {
    print qq{
  antsct-aging run script

  For help, run with "--help" or "--longitudinal --help".

};

    exit 1;
}

my $printHelp = 0;

Getopt::Long::Configure("pass_through");

GetOptions("help" => \$printHelp,
           "longitudinal" => \$runLongitudinal);


if ($printHelp) {
    if ($runLongitudinal) {
        system("/opt/scripts/runAntsLongCT_nonBIDS.pl --help");
    } else {
        system("/opt/scripts/runAntsCT_nonBIDS.pl --help");
    }
    exit 0;
}

if ($runLongitudinal) {
    system("/opt/scripts/runAntsLongCT_nonBIDS.pl --longitudinal @ARGV");
} else {
    system("/opt/scripts/runAntsCT_nonBIDS.pl @ARGV");
}