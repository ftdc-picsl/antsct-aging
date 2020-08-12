DKT31 labels from JLF, using OASIS-20-TRT from the Mindboggle project:

${ANTSPATH}antsJointLabelFusion.sh \
  -d 3 -q 0 -t T_template0_BrainCerebellum.nii.gz -o T_template0_DKT31 -f 1 -c 1 \
  -g mindboggleBrains/OASIS-TRT-20-1.nii.gz -l mindboggleLabels/OASIS-TRT-20-1_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-10.nii.gz -l mindboggleLabels/OASIS-TRT-20-10_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-11.nii.gz -l mindboggleLabels/OASIS-TRT-20-11_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-12.nii.gz -l mindboggleLabels/OASIS-TRT-20-12_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-13.nii.gz -l mindboggleLabels/OASIS-TRT-20-13_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-14.nii.gz -l mindboggleLabels/OASIS-TRT-20-14_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-15.nii.gz -l mindboggleLabels/OASIS-TRT-20-15_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-16.nii.gz -l mindboggleLabels/OASIS-TRT-20-16_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-17.nii.gz -l mindboggleLabels/OASIS-TRT-20-17_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-18.nii.gz -l mindboggleLabels/OASIS-TRT-20-18_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-19.nii.gz -l mindboggleLabels/OASIS-TRT-20-19_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-2.nii.gz -l mindboggleLabels/OASIS-TRT-20-2_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-20.nii.gz -l mindboggleLabels/OASIS-TRT-20-20_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-3.nii.gz -l mindboggleLabels/OASIS-TRT-20-3_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-4.nii.gz -l mindboggleLabels/OASIS-TRT-20-4_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-5.nii.gz -l mindboggleLabels/OASIS-TRT-20-5_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-6.nii.gz -l mindboggleLabels/OASIS-TRT-20-6_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-7.nii.gz -l mindboggleLabels/OASIS-TRT-20-7_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-8.nii.gz -l mindboggleLabels/OASIS-TRT-20-8_DKT31.nii.gz \
  -g mindboggleBrains/OASIS-TRT-20-9.nii.gz -l mindboggleLabels/OASIS-TRT-20-9_DKT31.nii.gz 


Mindboggle info
---------------

The Mindboggle-101 dataset is part of the Mindboggle project (http://mindboggle.info) and includes anatomically labeled brain surfaces and volumes derived from magnetic resonance images of 101 healthy individuals. The manually edited cortical labels follow sulcus landmarks according to the Desikan-Killiany-Tourville (DKT) labeling protocol: 

"101 labeled brain images and a consistent human cortical labeling protocol" 
Arno Klein, Jason Tourville. Frontiers in Brain Imaging Methods. 6:171. 
DOI: 10.3389/fnins.2012.00171 

Data and License 
All labeled data, including nifti volumes (nii), vtk surfaces (vtk), and FreeSurfer files (mgh, etc.) for each scanned "GROUP" (OASIS-TRT-20, NKI-TRT-20, NKI-RS-22, MMRR-21, HLN-12, etc.) are licensed under a Creative Commons License.
