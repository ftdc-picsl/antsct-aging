#!/usr/bin/perl -w
#
# Wrapper script, just figures out if longitudinal and then runs
# the appropriate script.

use strict;
use FindBin qw($Bin);
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long;


# Options with defaults
# Decide whether to run longitudinal or cross-sectional pipeline
