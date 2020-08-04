#!/usr/bin/perl -w
#
# Wrapper script for calling antsCorticalThickness.sh
# Trims neck as a first step
#

use strict;
use FindBin qw($Bin);
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long;


# Options
my $denoise = 1;
my $numThreads = 1;
my $runQuick = 0;
my $trimNeck = 1;
my $outputFileRoot = "";

my $usage = qq{
  $0  
      --anatomical-image 
      --output-dir 
      --output-file-root 
      [ options ]


  Runs antsCorticalThickness.sh on an anatomical image (usually T1w). trim_neck.sh is called first, then the trimmed data is passed
  to antsCorticalThickness.sh unless --trim-neck 0 is passed.

  The built-in template and priors are used.

  Required args:

   --anatomical-image
     Anatomical input image.

   --output-dir
     Output directory.

   --output-file-root
     Prepended onto output files. A sensible value of this would be "\${subject}_\${session}_" 
     (default = "${outputFileRoot}\").

  Options:

   --denoise
     Run denoising within the ACT pipeline (default = ${denoise}).
  
   --num-threads
     Maximum number of CPU threads to use. Set to 0 to use as many threads as there are cores 
     (default = ${numThreads}).

   --run-quick
     1 to use quick resgistration, 0 to use the default (default = ${runQuick}).

   --trim-neck 
     1 to run the trim_neck.sh script, 0 to use the raw data (default = ${trimNeck}).

  Output:
   Output is organized under the specified output directory.


};


if ($#ARGV < 0) {
    print $usage;
    exit 1;
}

# Get the directories containing programs we need
my $antsPath = $ENV{'ANTSPATH'};

if (!$antsPath || ! -f "${antsPath}antsRegistration") {
    die("Script requires ANTSPATH\n\t");
}

my ($anatomicalImage, $outputDir);

# Hard-coded template options
my $templateDir = "/opt/template";
my $extractionTemplate = "${templateDir}/T_template0.nii.gz";
my $registrationTemplate = "${templateDir}/T_template0_BrainCerebellum.nii.gz";
my $templateMask = "${templateDir}/T_template0_BrainCerebellumProbabilityMask.nii.gz";
my $templateRegMask = "${templateDir}/T_template0_BrainCerebellumRegistrationMask.nii.gz";
my $templatePriorSpec = "${templateDir}/priors/priors%d.nii.gz";

GetOptions ("anatomical-image=s" => \$anatomicalImage,
            "num-threads=i" => \$numThreads,
	    "output-dir=s" => \$outputDir,
	    "output-file-root=s" => \$outputFileRoot,
            "run-quick=i" => \$runQuick,
	    "trim-neck=i" => \$trimNeck
    )
    or die("Error in command line arguments\n");

(-f $anatomicalImage) or die "\nCannot find anatomical image: $anatomicalImage\n";

if ($numThreads == 0) {
  print "Maximum number of threads not set. Not setting ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS\n";
}
else {
  $ENV{'ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS'}=$numThreads;
}

if (! -d $outputDir) {
  system("mkdir -p $outputDir") == 0 or die "\nCannot create output directory $outputDir";
}

my $outputRoot = "${outputDir}/${outputFileRoot}";

# Write some version information to the output directory
system("${antsPath}antsRegistration --version > ${outputRoot}antsVersionInfo.txt");

my $antsInputImage = $anatomicalImage;

if ($trimNeck) {
  my $trimmedImage = "${outputRoot}NeckTrim.nii.gz";
  system("trim_neck.sh -d $anatomicalImage $trimmedImage > ${outputRoot}TrimNeckOutput.txt") == 0 
    or die("Neck trimming exited with nonzero status");
  $antsInputImage = $trimmedImage;
}

print "Running antsCorticalThickness.sh\n";

# run antsCT
my $antsCTCmd = "${antsPath}antsCorticalThickness.sh \\
   -d 3 \\
   -o ${outputRoot} \\
   -g ${denoise} \\
   -q ${runQuick} \\
   -x 25 \\
   -t ${registrationTemplate} \\
   -e ${extractionTemplate} \\
   -m ${templateMask} \\
   -f ${templateRegMask} \\
   -p ${templatePriorSpec} \\
   -a ${antsInputImage} > ${outputRoot}antsCorticalThicknessOutput.txt 2>&1";

my $antsExit = system("$antsCTCmd");

# Pass antsCT exit code back to calling program
exit($antsExit >> 8);

