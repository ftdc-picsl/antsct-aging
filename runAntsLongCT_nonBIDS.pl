#!/usr/bin/perl -w
#
# Wrapper script for calling antsLongitudinalCorticalThickness.sh
# Trims neck as a first step
#

use strict;
use FindBin qw($Bin);
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long;


# Options with defaults
my $denoise = 1;
my $keepTmp = 0;
my $numThreads = 1;
my $padMM = 25; # pad more to reduce SST drift problems
my $reproMode = 0;
my $resetOrigin = 1;
my $runQuick = 0;
my $trimNeckMode = "crop";

my $usage = qq{
  $0
      --anatomical-images
      --longitudinal
      --output-dir
      [ options ]

  Runs antsLongitudinalCorticalThickness.sh on anatomical images (usually T1w). trim_neck.sh is called first, then the trimmed
  data is passed to antsLongitudinalCorticalThickness.sh unless "--trim-neck-mode none" is passed. Multiple modalities are not
  supported.

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

   --anatomical-images
     Anatomical input image(s) from the same subject.

   --longitudinal
     Required to run the longitudinal pipeline.

   --output-dir
     Output directory for this subject.

  Options:

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

   --reset-origin
     If 1, set the origin of each image using the group template as a reference. This can stabilize single-subject
     templates by removing large translations due to different origin positions in the image headers (default = $resetOrigin).

   --run-quick
     1 or 2 to use quick(er) registration, good for testing but results will be suboptimal (default = ${runQuick}).

   --trim-neck-mode
     Controls how neck trimming is performed, if at all (default = $trimNeckMode). Either

     crop : Crop image to remove neck. This reduces the size of the T1w image input to the cortical
            thickness pipeline.

     mask : Mask image to remove neck. This sets the neck region to 0, but does not change the
            dimensions of the input image. This can be useful in conjunction with '--pad-input 0', to keep the
            outputs in the same voxel space as the input.

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
my (@anatomicalImages, $outputDir);

# Options with no defaults

# Has to be set to 1 or we ran the wrong script
my $runLongitudinal = 0;

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

GetOptions("anatomical-images=s{1,}" => \@anatomicalImages,
           "denoise=i" => \$denoise,
           "help" => sub { print $usage; exit(0); },
           "keep-files=i" => \$keepTmp,
           "longitudinal" => \$runLongitudinal,
           "mni-cortical-labels=s{1,}" => \@userMNICorticalLabels,
           "mni-labels=s{1,}" => \@userMNILabels,
           "num-threads=i" => \$numThreads,
           "output-dir=s" => \$outputDir,
           "pad-input=i" => \$padMM,
           "repro-mode=i" => \$reproMode,
           "reset-origin=i" => \$resetOrigin,
           "run-quick=i" => \$runQuick,
           "trim-neck-mode=s" => \$trimNeckMode
          )
    or die("Error in command line arguments\n");

foreach my $anat (@anatomicalImages) {
    (-f $anat) or die "\nCannot find anatomical image: $anat\n";
}

if (! $runLongitudinal) {
    die("This script is for longitudinal processing only. Use runAntsCT_nonBIDS.pl for cross-sectional processing");
}

my $numSessions = scalar(@anatomicalImages);

# Not sure if this really works for longitudinal processing because there's no option to pass it
# through to downstream scripts. But I think setting the seed + single thread is sufficient
if ($reproMode > 0) {
    print "Reproducibility mode enabled, setting ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1 and disabling random sampling\n";
    $ENV{'ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS'} = 1;
    # Need this to fix the seed for registration
    $ENV{'ANTS_RANDOM_SEED'} = 362321;
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

# Just used for logs and other script output, not for ants CT itself
my $outputRoot = "${outputDir}/antsct-aging-";

# Write some version information to the output directory
my $runTimestamp = `date`;
chomp($runTimestamp);

system("echo \"antsct-aging run $runTimestamp\" >> ${outputRoot}antsVersionInfo.txt");
system("${antsPath}antsRegistration --version >> ${outputRoot}antsVersionInfo.txt");

# Place neck trimmed, preprocessed images here
my $preprocDir = "${outputDir}/preprocInput";

if (! -d $preprocDir) {
    system("mkdir $preprocDir") == 0 or die "\nCannot create output directory $preprocDir";
}

# Array of preprocessed images input to ALCT.sh
my @preprocessedInput = ();

foreach my $inputAnatomical (@anatomicalImages) {

    my $preprocFilePrefix = fileparse($inputAnatomical, (".nii", ".nii.gz"));

    my $preprocOutputRoot = "${preprocDir}/${preprocFilePrefix}_";

    my $antsInputImage = "${preprocOutputRoot}Preprocessed.nii.gz";

    if (-f $antsInputImage) {
        print "Found preprocessed image $antsInputImage, skipping preprocessing\n";
        push(@preprocessedInput, $antsInputImage);
        next;
    }

    if (($trimNeckMode eq "crop") || ($trimNeckMode eq "mask")) {
        my $trimNeckOpts = "-d -c 10 -m ${preprocOutputRoot}NeckTrimMask.nii.gz";

        if ($trimNeckMode eq "mask") {
         $trimNeckOpts = $trimNeckOpts . " -r ";
        }

        system("trim_neck.sh $trimNeckOpts $inputAnatomical $antsInputImage > ${preprocOutputRoot}TrimNeckOutput.txt") == 0
                or die("Neck trimming exited with nonzero status");
    }
    elsif ($trimNeckMode eq "none") {
        system("cp $inputAnatomical $antsInputImage") == 0 or die("Cannot create preprocessed anatomical image");
    }
    else {
        die("Unrecognized neck trim option $trimNeckMode");
    }

    # pad image
    if (${padMM} > 0) {
        print "Padding input image [ $inputAnatomical ] by ${padMM}mm\n";
        system("c3d $antsInputImage -pad ${padMM}x${padMM}x${padMM}mm ${padMM}x${padMM}x${padMM}mm 0 -o $antsInputImage") == 0
            or die("Cannot pad input image");
    }

    if (${resetOrigin} > 0) {
        print "Resetting origin of input image [ $inputAnatomical ]\n";
        resetOrigin($antsInputImage, $extractionTemplate, $templateRegMask);
    }

    push(@preprocessedInput, $antsInputImage);
}


print "Running antsLongitudinalCorticalThickness.sh\n";

# run antsCT
my $inputImageString = join(" ", @preprocessedInput);

my $antsCTCmd = "${antsPath}antsLongitudinalCorticalThickness.sh \\
   -d 3 \\
   -o ${outputDir}/ \\
   -g ${denoise} \\
   -q ${runQuick} \\
   -b ${keepTmp} \\
   -x 25 \\
   -t ${registrationTemplate} \\
   -e ${extractionTemplate} \\
   -m ${templateMask} \\
   -f ${templateRegMask} \\
   -p ${templatePriorSpec} \\
   -y 1 \\
   ${inputImageString} >> ${outputDir}/antsLongitudinalCorticalThicknessOutput.txt 2>&1";

# Log ACT command
open(my $fh, ">>", "${outputRoot}antsLongitudinalCorticalThicknessCmd.sh");
print $fh "\n --- antct-aging run $runTimestamp --- \n";
print $fh $antsCTCmd;
close($fh);

my $antsExit = system($antsCTCmd);

if ($antsExit > 0) {
    die("ants cortical thickness exited with code " . (${antsExit} >> 8));
}

# Each timepoint is output to a separate directory under outputDir
# Directory name is the basename of the input image in @preprocessedInput, followed by
# a numeric prefix starting with _0
my @sessionFilePrefixes = ();
my @sessionDirs = ();

my $sessionCounter = 0;

foreach my $inputImage (@preprocessedInput) {
    my $filePrefix = fileparse($inputImage, (".nii", ".nii.gz"));
    push(@sessionFilePrefixes, $filePrefix);
    push(@sessionDirs, "${outputDir}/${filePrefix}_${sessionCounter}");
    $sessionCounter++;
}

print "Warping labels to each session space\n";

# Warp Lausanne, DKT31, Schaefer labels to subject space

# First get GM mask, which we will define as thickness > 0
# This incorporates some topology constraints to keep the labels in cortex

for (my $i = 0; $i < $numSessions; $i++) {
    my $sessionCorticalMask = "${sessionDirs[$i]}/${sessionFilePrefixes[$i]}CorticalMask.nii.gz";
    my $sessionOutputRoot = "${sessionDirs[$i]}/${sessionFilePrefixes[$i]}";

    system("${antsPath}ThresholdImage 3 ${sessionOutputRoot}CorticalThickness.nii.gz " .
            "$sessionCorticalMask 0.0001 1000");

    propagateCorticalLabelsToNativeSpace($sessionCorticalMask, "${templateDir}/labels/DKT31/DKT31.nii.gz", 0,
                                        $sessionOutputRoot, "DKT31");

    propagateCorticalLabelsToNativeSpace($corticalMask, "${templateDir}/labels/BrainCOLOR/BrainCOLORCortical.nii.gz", 0,
                                        $outputRoot, "BrainColorCortical");

    # Scales go up to 250 and even 500, but they take a long time to interpolate
    my @lausanneScales = (33, 60, 125, 250);

    foreach my $scale (@lausanneScales) {
        propagateCorticalLabelsToNativeSpace($sessionCorticalMask,
            "${templateDir}/labels/LausanneCortical/Lausanne_Scale${scale}.nii.gz", 0, $sessionOutputRoot,
            "LausanneCorticalScale${scale}");
    }

    # Schaefer labels from MNI space

    my @schaeferScales = (100, 200, 300, 400, 500);
    my @schaeferNetworks = (7, 17);

    foreach my $net (@schaeferNetworks) {
        foreach my $scale (@schaeferScales) {
            propagateCorticalLabelsToNativeSpace($sessionCorticalMask,
            "${templateDir}/MNI152NLin2009cAsym/" .
            "tpl-MNI152NLin2009cAsym_res-01_atlas-Schaefer2018_desc-${scale}Parcels${net}Networks_dseg.nii.gz",
            1, $sessionOutputRoot, "Schaefer2018_${scale}Parcels${net}Networks");
        }
    }

    # Subcortical brainCOLOR labels
    warpLabelsToNativeSpace("${templateDir}/labels/BrainCOLOR/BrainCOLORSubcortical.nii.gz", 0, $sessionOutputRoot,
                            "BrainColorSubcortical");
    # warp user-defined labels
    my @userImageSuffixes = (".nii", ".nii.gz");

    foreach my $userMNICorticalLabelImage (@userMNICorticalLabels) {
        my $labelName = fileparse($userMNICorticalLabelImage, @userImageSuffixes);
        propagateCorticalLabelsToNativeSpace($sessionCorticalMask, $userMNICorticalLabelImage, 1, $sessionOutputRoot, $labelName);
    }

    foreach my $userMNIImage (@userMNILabels) {
        my $labelName = fileparse($userMNIImage, @userImageSuffixes);
        warpLabelsToNativeSpace($userMNIImage, 1, $sessionOutputRoot, $labelName);
    }

}

# Pass antsCT exit code back to calling program
exit($antsExit >> 8);


# Reset the origin of an image to match a reference image
#
# Since this modifies its input, it should be called on a copy of the image
# It's best to apply the neck trim first
#
# args: inputImage - image to reset origin - note original will be overwritten
#       referenceImage - image to use as reference
#       maskImage - mask image to use for registration, in reference image space
#
# resetOrigin($inputImage, $referenceImage, $maskImage)
#
sub resetOrigin {

    my ($inputImage, $referenceImage, $maskImage) = @_;

    # Quick N4 on the input image

    # use fileparse to get directory and file prefix of input image
    my ($inputFilePrefix, $preprocDir) = fileparse($inputImage, (".nii", ".nii.gz"));

    my $n4Image = "${preprocDir}/${inputFilePrefix}_N4.nii.gz";

    system("${antsPath}N4BiasFieldCorrection -d 3 -i $inputImage -o $n4Image -b [ 160 ] -c [ 25x25x25, 0.001 ] --verbose") == 0
        or die("Cannot run N4 on $inputImage");

    my $regPrefix = "${preprocDir}/${inputFilePrefix}_ToReference_";

    # Register input image to reference image using antsRegistrationSyNQuick.sh
    # use maskImage as a metric mask
    system("${antsPath}antsRegistrationSyNQuick.sh -d 3 -f $referenceImage -m $n4Image -o $regPrefix -x $maskImage") == 0
        or die("Cannot register $inputImage to $referenceImage");

    # Write the origin of the reference image to a file, then warp it to the input image space
    my $refOrigin = "${regPrefix}RefOrigin.csv";

    open($fh, ">", $refOrigin);
    print $fh "x,y,z,t\n0,0,0,0\n";
    close($fh);

    # apply the transform to reforigin
    system("${antsPath}antsApplyTransformsToPoints -d 3 -i $refOrigin -o ${regPrefix}RefOriginInInputSpace.csv " .
           "-t ${regPrefix}0GenericAffine.mat") == 0
        or die("Cannot apply transform to reference origin");

    # Read the warped coordinates back in
    open($fh, "<", "${regPrefix}RefOriginInInputSpace.csv");
    my $line = <$fh>; # header
    $line = <$fh>;
    close($fh);

    chomp($line);
    my @refCoordsWarped = split(",", $line);

    my $movingOrigin = "${regPrefix}MovingOrigin.txt";

    # Read the origin of the input image
    system("${antsPath}PrintHeader $inputImage 0 > $movingOrigin") == 0
        or die("Cannot get origin of $inputImage");

    open($fh, "<", $movingOrigin);
    $line = <$fh>; # AxBxC
    close($fh);

    chomp($line);
    my @movingOrigin = split("x", $line);

    # New origin is the difference between the warped reference origin and the input origin
    my @newOrigin = ($movingOrigin[0] - $refCoordsWarped[0], $movingOrigin[1] - $refCoordsWarped[1],
                     $movingOrigin[2] - $refCoordsWarped[2]);

    system("${antsPath}SetOrigin 3 $inputImage $inputImage ${newOrigin[0]} ${newOrigin[1]} ${newOrigin[2]}") == 0
        or die("Cannot set origin of $inputImage to @newOrigin");

    # Cleanup extra files
    system("rm -f ${refOrigin} ${regPrefix}RefOriginInInputSpace.csv $movingOrigin $n4Image ${regPrefix}");
}


# Map cortical labels to the subject GM, mask with GM and propagate through GM mask
#
# args: corticalMask - binary image to label
#       labelImage - label image in template space, to warp
#       mniSpace - true if labels are in MNI152 space, false if they are in the local template space
#       sessionOutputRoot - output root for session processing. Used to find warps and name output
#       outputLabelName - added to output root, eg "DKT31"
#
# propagateCorticalLabelsToNativeSpace($gmMask, $labelImage, $mniSpace, $sessionOutputRoot, $outputLabelName)
#
# In addition to propagating the labels, make a QC file showing overlap between labels
# before and after label propagation step.
#
sub propagateCorticalLabelsToNativeSpace {

    my ($corticalMask, $labelImage, $mniSpace, $sessionOutputRoot, $outputLabelName) = @_;

    if (-f "${sessionOutputRoot}${outputLabelName}.nii.gz") {
        print "Found label image ${sessionOutputRoot}${outputLabelName}.nii.gz, skipping\n";
        return;
    }

    my $tmpLabels = "${sessionOutputRoot}tmp${outputLabelName}.nii.gz";

    my $warpString = "-t ${sessionOutputRoot}GroupTemplateToSubjectWarp.nii.gz";

    if ($mniSpace) {
        $warpString = "-t ${sessionOutputRoot}GroupTemplateToSubjectWarp.nii.gz \\
          -t ${templateDir}/MNI152NLin2009cAsym/MNI152NLin2009cAsymToTemplateWarp.nii.gz";
    }

    my $warpCmd = "${antsPath}antsApplyTransforms \\
      -d 3 -r ${sessionOutputRoot}ExtractedBrain0N4.nii.gz \\
      $warpString \\
      -n GenericLabel \\
      -i $labelImage \\
      -o $tmpLabels";

    (system($warpCmd) == 0) or die("Could not warp labels $labelImage to subject space");

    (system("${antsPath}ImageMath 3 ${sessionOutputRoot}${outputLabelName}.nii.gz PropagateLabelsThroughMask " .
            "$corticalMask $tmpLabels 8 0")) == 0
          or die("Could not propagate labels $labelImage through cortical mask");

    system("${antsPath}LabelOverlapMeasures 3 ${sessionOutputRoot}${outputLabelName}.nii.gz $tmpLabels " .
           "${sessionOutputRoot}${outputLabelName}WarpedVsPropagated.csv");

    system("rm -f $tmpLabels");
}


# Map a generic label set to the subject's native space
#
# args: labelImage - label image in template space, to warp
#       mniSpace - true if labels are in MNI152 space, false if they are in the local template space
#       sessionOutputRoot - output root for session processing. Used to find warps and name output
#       outputLabelName - added to output root, eg "DKT31"
#
# warpLabelsToNativeSpace($labelImage, $mniSpace, $sessionOutputRoot, $outputLabelName)
#
#
sub warpLabelsToNativeSpace {

    my ($labelImage, $mniSpace, $sessionOutputRoot, $outputLabelName) = @_;

    if (-f "${sessionOutputRoot}${outputLabelName}.nii.gz") {
        print "Found label image ${sessionOutputRoot}${outputLabelName}.nii.gz, skipping\n";
        return;
    }

    my $warpString = "-t ${sessionOutputRoot}GroupTemplateToSubjectWarp.nii.gz";

    if ($mniSpace) {
        $warpString = "-t ${sessionOutputRoot}GroupTemplateToSubjectWarp.nii.gz \\
          -t ${templateDir}/MNI152NLin2009cAsym/MNI152NLin2009cAsymToTemplateWarp.nii.gz";
    }

    my $warpCmd = "${antsPath}antsApplyTransforms \\
      -d 3 -r ${sessionOutputRoot}ExtractedBrain0N4.nii.gz \\
      $warpString \\
      -n GenericLabel \\
      -i $labelImage \\
      -o ${sessionOutputRoot}${outputLabelName}.nii.gz";

    (system($warpCmd) == 0) or die("Could not warp labels $labelImage to subject space");
}
