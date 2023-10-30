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


# Options with defaults
my $antsCTStage = 0;
my $brainMaskMode = "ants";
my $brainMaskImage = "";
my $denoise = 1;
my $keepTmp = 0;
my $numThreads = 1;
my $padMM = 10;
my $reproMode = 0;
my $runQuick = 0;
my $trimNeckMode = "crop";
my $outputFileRoot = "";

my $usage = qq{
  $0
      --anatomical-image
      --output-dir
      --output-file-root
      [ options ]


  Runs antsCorticalThickness.sh on an anatomical image (usually T1w). trim_neck.sh is called first, then the trimmed data
  is passed to antsCorticalThickness.sh unless "--trim-neck-mode none" is passed.

  All image inputs should be NIFTI with extension ".nii.gz".

  The built-in template and priors are used to compute thickness. Several built-in label sets are warped to the anatomical
  space automatically. Cortical labels are propagated to the mask defined by thickness > 0:

    DKT31, the Desikan-Killiany-Tourville parcellation from Mindboggle

    Lausanne, subdivisions of the DKT31 labels to finer scales of (60, 125, 250) parcels

    Schaefer, the Schaefer et al 2018 functional cortical parcellation, copied from templateflow
    (7 and 17 networks) x (100, 200, 300, 400, 500) parcels.


  Subcortical labels are warped to the subject anatomical space, but not processed further:

    BrainCOLOR, labels from Neuromorphometrics for the MICCAI 2012 segmentation challenge.

  Please see the README files in the container source repository for informations and citations.

  User-defined label sets in the MNI152NLin2009cAsym space can be added at run time.

  Required args:

   --anatomical-image
     Anatomical input image.

   --output-dir
     Output directory.

   --output-file-root
     Prepended onto output files. A sensible value of this would be "\${subject}_\${session}_"
     (default = "${outputFileRoot}\").

  Options:

   --antsct-stage
     Run a particular stage of the ACT pipeline:

        0: all stages
        1: brain extraction
        2: template registration
        3: tissue segmentation
        4: template registration (improved)
        5: DiReCT cortical thickness
        6: qc, quality control and summary measurements

     (default = ${antsCTStage}).

   --brain-mask-image
     A binary brain mask for the anatomical input image. Implies `--brain-mask-mode image`. Neck trimming should
     be set to "mask" or "none". The mask should have the exact same dimensions as the input. The mask will be
     padded to match the input image if padding is not disabled with `--pad-input 0`.

   --brain-mask-mode
     Controls how brain masking is performed. Either
          ants   : antsBrainExtraction.sh

     This option has no effect if a brain mask image is supplied at run time (default = ${brainMaskMode}).

   --denoise
     Run denoising within the ACT pipeline (default = ${denoise}).

   --keep-files
     Retain all temporary files in the ACT pipeline (default = ${keepTmp}).

   --mni-cortical-labels
     One or more cortical label images in the MNI152NLin2009cAsym space, to be propagated to the
     subject's cortical mask. Use this option if the label set contains only cortical labels.

   --mni-labels
     One or more generic label images in the MNI152NLin2009cAsym space, to be warped to the subject space.

   --num-threads
     Maximum number of CPU threads to use. Set to 0 to use as many threads as there are cores (default = ${numThreads}).

   --pad-input
     Pad input image with this amount (mm). This padding is applied after neck trimming (default = ${padMM}).

   --repro-mode
     If 1, disable multi-threading and all random sampling, which should provide reproducible results
     between runs. This is useful for testing, but slower if multiple cores are available (default = $reproMode).

   --run-quick
     1 to use quick registration, good for testing but results will be suboptimal (default = ${runQuick}).

   --trim-neck-mode
     Controls how neck trimming is performed, if at all (default = $trimNeckMode). Either

     crop : Crop image to remove neck. This reduces the size of the T1w image input to the cortical
            thickness pipeline.

     mask : Mask image to remove neck. This sets the neck region to 0, but does not change the
            dimensions of the input image, so the output shares the same voxel space.

     none : No neck trimming is performed.

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

# Required args
my ($anatomicalImage, $outputDir);

# Options with no defaults

#  Generic MNI label set
my @userMNILabels = ();

# Cortical labels only
my @userMNICorticalLabels = ();

# Hard-coded template options
my $templateDir = "/opt/template";
my $extractionTemplate = "${templateDir}/T_template0.nii.gz";
my $registrationTemplate = "${templateDir}/T_template0_BrainCerebellum.nii.gz";
my $templateMask = "${templateDir}/T_template0_BrainCerebellumProbabilityMask.nii.gz";
my $templateRegMask = "${templateDir}/T_template0_BrainCerebellumRegistrationMask.nii.gz";
my $templatePriorSpec = "${templateDir}/priors/priors%d.nii.gz";

GetOptions("anatomical-image=s" => \$anatomicalImage,
           "antsct-stage=i" => \$antsCTStage,
           "brain-mask-image=s" => \$brainMaskImage,
           "brain-mask-mode=s" => \$brainMaskMode,
           "denoise=i" => \$denoise,
           "help" => sub { print $usage; exit(0); },
           "keep-files=i" => \$keepTmp,
           "mni-cortical-labels=s{1,}" => \@userMNICorticalLabels,
           "mni-labels=s{1,}" => \@userMNILabels,
           "num-threads=i" => \$numThreads,
           "output-dir=s" => \$outputDir,
           "output-file-root=s" => \$outputFileRoot,
           "pad-input=i" => \$padMM,
           "repro-mode=i" => \$reproMode,
           "run-quick=i" => \$runQuick,
           "trim-neck-mode=s" => \$trimNeckMode
          )
    or die("Error in command line arguments\n");

(-f $anatomicalImage) or die "\nCannot find anatomical image: $anatomicalImage\n";

my $useRandomSeeding = 1;

if ($reproMode > 0) {
    print "Reproducibility mode enabled, setting ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1 and disabling random sampling\n";
    $ENV{'ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS'} = 1;
    # Need this to fix the seed for registration
    $ENV{'ANTS_RANDOM_SEED'} = 362321;
    # Pass this to the script to fix Atropos seed
    $useRandomSeeding = 0;
}
elsif ($numThreads == 0) {
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
my $runTimestamp = `date`;
chomp($runTimestamp);

system("echo \"antsct-aging run $runTimestamp\" >> ${outputRoot}antsVersionInfo.txt");
system("${antsPath}antsRegistration --version >> ${outputRoot}antsVersionInfo.txt");

my $antsInputImage = "${outputRoot}PreprocessedInput.nii.gz";

if (($trimNeckMode eq "crop") || ($trimNeckMode eq "mask")) {
    my $trimNeckOpts = "-d -c 10 -m ${outputRoot}NeckTrimMask.nii.gz";

    if ($trimNeckMode eq "mask") {
        $trimNeckOpts = $trimNeckOpts . " -r ";
    }

    system("trim_neck.sh $trimNeckOpts $anatomicalImage $antsInputImage > ${outputRoot}TrimNeckOutput.txt") == 0
      or die("Neck trimming exited with nonzero status");
}
elsif ($trimNeckMode eq "none") {
    system("cp $anatomicalImage $antsInputImage") == 0 or die("Cannot create preprocessed anatomical image");
}
else {
    die("Unrecognized neck trim option $trimNeckMode");
}

# pad image
if (${padMM} > 0) {
    print "Padding input image by ${padMM}mm\n";
    system("c3d $antsInputImage -pad ${padMM}x${padMM}x${padMM}mm ${padMM}x${padMM}x${padMM}mm 0 -o $antsInputImage") == 0
      or die("Cannot pad input image");
}

# Import or define brain mask outside of antsCT, if requested
if (-f ${brainMaskImage} ) {
    print "Using brain mask image $brainMaskImage\n";

    if ($trimNeckMode eq "crop") {
        die("Neck cannot be cropped when a brain mask image is present");
    }

    if (${padMM} > 0) {
        print "Padding input mask by ${padMM}mm\n";
        system("c3d $brainMaskImage -pad ${padMM}x${padMM}x${padMM}mm ${padMM}x${padMM}x${padMM}mm 0 -o  ${outputRoot}BrainExtractionMask.nii.gz") == 0
          or die("Cannot pad mask image");
    }
    else {
        system("cp $brainMaskImage ${outputRoot}BrainExtractionMask.nii.gz");
    }
}
elsif (!($brainMaskMode eq "ants")) {
    # Eventually will have options here to do something else, like antspynet
    die("Unknown brain mask mode $brainMaskMode");
}

print "Running antsCorticalThickness.sh\n";

# run antsCT
my $antsCTCmd = "${antsPath}antsCorticalThickness.sh \\
   -d 3 \\
   -o ${outputRoot} \\
   -g ${denoise} \\
   -q ${runQuick} \\
   -k ${keepTmp} \\
   -x 25 \\
   -t ${registrationTemplate} \\
   -e ${extractionTemplate} \\
   -m ${templateMask} \\
   -f ${templateRegMask} \\
   -p ${templatePriorSpec} \\
   -u ${useRandomSeeding} \\
   -a ${antsInputImage} \\
   -y ${antsCTStage} >> ${outputRoot}antsCorticalThicknessOutput.txt 2>&1";

# Log ACT command
open(my $fh, ">>", "${outputRoot}antsCorticalThicknessCmd.sh");
print $fh "\n --- antct-aging run $runTimestamp --- \n";
print $fh $antsCTCmd;
close($fh);

my $antsExit = system($antsCTCmd);

if ($antsExit > 0) {
    die("ants cortical thickness exited with code " . (${antsExit} >> 8));
}

if (! -f "${outputRoot}TemplateToSubject0Warp.nii.gz") {
    print "Template warps not found, cannot proceed with label propagation\n";
    # Exit 0 here, because it should only happen if staged execution was run
    exit(${antsExit} >> 8);
}

print "Warping labels to subject space\n";

# Warp Lausanne and DKT31 labels to subject space

# First get GM mask, which we will define as thickness > 0
# This incorporates some topology constraints to keep the labels in cortex
my $corticalMask = "${outputRoot}CorticalMask.nii.gz";

system("${antsPath}ThresholdImage 3 ${outputRoot}CorticalThickness.nii.gz $corticalMask 0.0001 1000");

propagateCorticalLabelsToNativeSpace($corticalMask, "${templateDir}/labels/DKT31/DKT31.nii.gz", 0, $outputRoot, "DKT31");

# Scales go up to 250 and even 500, but they take a long time to interpolate
my @lausanneScales = (33, 60, 125, 250);

foreach my $scale (@lausanneScales) {
    propagateCorticalLabelsToNativeSpace($corticalMask, "${templateDir}/labels/LausanneCortical/Lausanne_Scale${scale}.nii.gz",
                                         0, $outputRoot, "LausanneCorticalScale${scale}");
}

my @schaeferScales = (100, 200, 300, 400, 500);
my @schaeferNetworks = (7, 17);

foreach my $net (@schaeferNetworks) {
    foreach my $scale (@schaeferScales) {
        propagateCorticalLabelsToNativeSpace($corticalMask,
        "${templateDir}/MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_atlas-Schaefer2018_desc-${scale}Parcels${net}Networks_dseg.nii.gz",
        1, $outputRoot, "Schaefer2018_${scale}Parcels${net}Networks");
    }
}

# Subcortical brainCOLOR labels
warpLabelsToNativeSpace("${templateDir}/labels/BrainCOLOR/BrainCOLORSubcortical.nii.gz", 0, $outputRoot, "BrainColorSubcortical");

# warp user-defined labels
my @userImageSuffixes = (".nii", ".nii.gz");

foreach my $userMNICorticalLabelImage (@userMNICorticalLabels) {
    my $labelName = fileparse($userMNICorticalLabelImage, @userImageSuffixes);
    propagateCorticalLabelsToNativeSpace($corticalMask, $userMNICorticalLabelImage, 1, $outputRoot, $labelName);
}

foreach my $userMNIImage (@userMNILabels) {
    my $labelName = fileparse($userMNIImage, @userImageSuffixes);
    warpLabelsToNativeSpace($userMNIImage, 1, $outputRoot, $labelName);
}

# Pass antsCT exit code back to calling program
exit($antsExit >> 8);


# Map cortical labels to the subject GM, mask with GM and propagate through GM mask
#
# args: corticalMask - binary image to label
#       labelImage - label image in template space, to warp
#       mniSpace - true if labels are in MNI152 space, false if they are in the local template space
#       outputRoot - output root for antsCT. Used to find warps and name output
#       outputLabelName - added to output root, eg "DKT31"
#
# propagateCorticalLabelsToNativeSpace($gmMask, $labelImage, $mniSpace, $outputRoot, $outputLabelName)
#
# In addition to propagating the labels, make a QC file showing overlap between labels
# before and after label propagation step.
#
sub propagateCorticalLabelsToNativeSpace {

    my ($corticalMask, $labelImage, $mniSpace, $outputRoot, $outputLabelName) = @_;

    my $tmpLabels = "${outputRoot}tmp${outputLabelName}.nii.gz";

    my $warpString = "-t ${outputRoot}TemplateToSubject1GenericAffine.mat \\
      -t ${outputRoot}TemplateToSubject0Warp.nii.gz";

    if ($mniSpace) {
        $warpString = "-t ${outputRoot}TemplateToSubject1GenericAffine.mat \\
          -t ${outputRoot}TemplateToSubject0Warp.nii.gz \\
          -t ${templateDir}/MNI152NLin2009cAsym/MNI152NLin2009cAsymToTemplateWarp.nii.gz";
    }

    my $warpCmd = "${antsPath}antsApplyTransforms \\
      -d 3 -r ${outputRoot}ExtractedBrain0N4.nii.gz \\
      $warpString \\
      -n GenericLabel \\
      -i $labelImage \\
      -o $tmpLabels";

    (system($warpCmd) == 0) or die("Could not warp labels $labelImage to subject space");

    (system("${antsPath}ImageMath 3 ${outputRoot}${outputLabelName}.nii.gz PropagateLabelsThroughMask $corticalMask $tmpLabels 8 0")) == 0
          or die("Could not propagate labels $labelImage through cortical mask");

    system("${antsPath}LabelOverlapMeasures 3 ${outputRoot}${outputLabelName}.nii.gz $tmpLabels ${outputRoot}${outputLabelName}WarpedVsPropagated.csv");

    system("rm -f $tmpLabels");
}


# Map a generic label set to the subject's native space
#
# args: labelImage - label image in template space, to warp
#       mniSpace - true if labels are in MNI152 space, false if they are in the local template space
#       outputRoot - output root for antsCT. Used to find warps and name output
#       outputLabelName - added to output root, eg "DKT31"
#
# warpLabelsToNativeSpace($labelImage, $mniSpace, $outputRoot, $outputLabelName)
#
#
sub warpLabelsToNativeSpace {

    my ($labelImage, $mniSpace, $outputRoot, $outputLabelName) = @_;

    my $warpString = "-t ${outputRoot}TemplateToSubject1GenericAffine.mat \\
      -t ${outputRoot}TemplateToSubject0Warp.nii.gz";

    if ($mniSpace) {
        $warpString = "-t ${outputRoot}TemplateToSubject1GenericAffine.mat \\
          -t ${outputRoot}TemplateToSubject0Warp.nii.gz \\
          -t ${templateDir}/MNI152NLin2009cAsym/MNI152NLin2009cAsymToTemplateWarp.nii.gz";
    }

    my $warpCmd = "${antsPath}antsApplyTransforms \\
      -d 3 -r ${outputRoot}ExtractedBrain0N4.nii.gz \\
      $warpString \\
      -n GenericLabel \\
      -i $labelImage \\
      -o ${outputRoot}${outputLabelName}.nii.gz";

    (system($warpCmd) == 0) or die("Could not warp labels $labelImage to subject space");
}
