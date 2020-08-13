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
            "denoise=i" => \$denoise,
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
   
    if (!-f $trimmedImage) {
        system("trim_neck.sh -d $anatomicalImage $trimmedImage > ${outputRoot}TrimNeckOutput.txt") == 0 
          or die("Neck trimming exited with nonzero status");
    }
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
   -a ${antsInputImage} >> ${outputRoot}antsCorticalThicknessOutput.txt 2>&1";

my $antsExit = system($antsCTCmd);

print "Warping cortical labels to subject space\n";

# Warp Lausanne and DKT31 labels to subject space

# first get GM mask
my $gmMask = "${outputRoot}GMMask.nii.gz";

system("${antsPath}ThresholdImage 3 ${outputRoot}BrainSegmentation.nii.gz $gmMask 2 2");

propagateCorticalLabels($gmMask, "${templateDir}/labels/DKT31/DKT31.nii.gz", $outputRoot, "DKT31");

# Scales go up to 250 and even 500, but they take a long time to interpolate
my @lausanneScales = (33, 60, 125);

foreach my $scale (@lausanneScales) {
    propagateCorticalLabels($gmMask, "${templateDir}/labels/LausanneCortical/Lausanne_Scale${scale}.nii.gz", $outputRoot, "LausanneCorticalScale${scale}");
}

# Pass antsCT exit code back to calling program
exit($antsExit >> 8);


# Map cortical labels to the subject GM, mask with GM and propagate through GM mask
#
# args: gmMask - GM binary image, derived from BrainSegmentation.nii.gz
#       labelImage - label image in template space, to warp
#       outputRoot - output root for antsCT. Used to find warps and name output
#       outputLabelName - added to output root, eg "DKT31"
#
# propagateCorticalLabels($gmMask, $labelImage, $outputRoot, $outputLabelName) 
#
sub propagateCorticalLabels {

    my ($gmMask, $labelImage, $outputRoot, $outputLabelName) = @_;

    my $tmpLabels = "${outputRoot}tmp${outputLabelName}.nii.gz";

    my $warpCmd = "${antsPath}antsApplyTransforms \\
      -d 3 -r ${outputRoot}ExtractedBrain0N4.nii.gz \\
      -t ${outputRoot}TemplateToSubject1GenericAffine.mat \\
      -t ${outputRoot}TemplateToSubject0Warp.nii.gz \\
      -n GenericLabel \\
      -i $labelImage \\
      -o $tmpLabels";

    (system($warpCmd) == 0) or die("Could not warp labels $labelImage to subject space");

    (system("ImageMath 3 ${outputRoot}${outputLabelName}.nii.gz PropagateLabelsThroughMask $gmMask $tmpLabels 10 0")) == 0 
          or die("Could not propagate labels $labelImage through GM mask");

    system("rm -f $tmpLabels");
}
