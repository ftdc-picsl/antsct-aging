BrainCOLOR labels defined in the template by JLF

${ANTSPATH}antsJointLabelFusion.sh \
  -d 3 -q 0 -t T_template0_BrainCerebellum.nii.gz -o T_template0_brainCOLOR -f 1 -c 1 \
  -g Brains/1000_3.nii.gz -l Segmentations/1000_3_seg.nii.gz \
  -g Brains/1001_3.nii.gz -l Segmentations/1001_3_seg.nii.gz \
  -g Brains/1002_3.nii.gz -l Segmentations/1002_3_seg.nii.gz \
  -g Brains/1003_3.nii.gz -l Segmentations/1003_3_seg.nii.gz \
  -g Brains/1004_3.nii.gz -l Segmentations/1004_3_seg.nii.gz \
  -g Brains/1005_3.nii.gz -l Segmentations/1005_3_seg.nii.gz \
  -g Brains/1006_3.nii.gz -l Segmentations/1006_3_seg.nii.gz \
  -g Brains/1007_3.nii.gz -l Segmentations/1007_3_seg.nii.gz \
  -g Brains/1008_3.nii.gz -l Segmentations/1008_3_seg.nii.gz \
  -g Brains/1009_3.nii.gz -l Segmentations/1009_3_seg.nii.gz \
  -g Brains/1010_3.nii.gz -l Segmentations/1010_3_seg.nii.gz \
  -g Brains/1011_3.nii.gz -l Segmentations/1011_3_seg.nii.gz \
  -g Brains/1012_3.nii.gz -l Segmentations/1012_3_seg.nii.gz \
  -g Brains/1013_3.nii.gz -l Segmentations/1013_3_seg.nii.gz \
  -g Brains/1014_3.nii.gz -l Segmentations/1014_3_seg.nii.gz \
  -g Brains/1015_3.nii.gz -l Segmentations/1015_3_seg.nii.gz \
  -g Brains/1017_3.nii.gz -l Segmentations/1017_3_seg.nii.gz \
  -g Brains/1018_3.nii.gz -l Segmentations/1018_3_seg.nii.gz \
  -g Brains/1019_3.nii.gz -l Segmentations/1019_3_seg.nii.gz \
  -g Brains/1036_3.nii.gz -l Segmentations/1036_3_seg.nii.gz \
  -g Brains/1101_3.nii.gz -l Segmentations/1101_3_seg.nii.gz \
  -g Brains/1104_3.nii.gz -l Segmentations/1104_3_seg.nii.gz \
  -g Brains/1107_3.nii.gz -l Segmentations/1107_3_seg.nii.gz \
  -g Brains/1110_3.nii.gz -l Segmentations/1110_3_seg.nii.gz \
  -g Brains/1113_3.nii.gz -l Segmentations/1113_3_seg.nii.gz \
  -g Brains/1116_3.nii.gz -l Segmentations/1116_3_seg.nii.gz \
  -g Brains/1119_3.nii.gz -l Segmentations/1119_3_seg.nii.gz \
  -g Brains/1122_3.nii.gz -l Segmentations/1122_3_seg.nii.gz \
  -g Brains/1125_3.nii.gz -l Segmentations/1125_3_seg.nii.gz \
  -g Brains/1128_3.nii.gz -l Segmentations/1128_3_seg.nii.gz


Cortical labels
---------------

Cortical labels (labels >= 100) not listed as "ignore" in the segmentation
challenge are included. Ignored labels have been removed. See the label
definitions and the segmentation protocol at

http://neuromorphometrics.com/Seg/


Subcortical labels
------------------

Subcortical labels (labelID < 100) not listed as "ignore" in the segmentation
challenge are included. Ignored labels have been removed. See the label
definitions and the segmentation protocol at

http://neuromorphometrics.com/Seg/


Subcortical Thickness Labels
----------------------------

These are just internally to prevent propagation of cortical labels into these
structures.


Original atlas information
--------------------------

These data were provided for use in the MICCAI 2012 Grand Challenge and Workshop
on Multi-Atlas Labeling [B. Landman, S. Warfield, MICCAI 2012 workshop on
multi-atlas labeling, in: MICCAI Grand Challenge and Workshop on Multi-Atlas
Labeling, CreateSpace Independent Publishing Platform, Nice, France, 2012.].
The data is released under the Creative Commons Attribution-NonCommercial
license (CC BY-NC) with no end date.  Original MRI scans are from OASIS
(https://www.oasis-brains.org/).  Labelings were provided by Neuromorphometrics,
Inc. (http://Neuromorphometrics.com/) under academic subscription.
