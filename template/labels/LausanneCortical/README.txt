Lausanne cortical labels
------------------------

These labels were produced by running FreeSurfer 6 and then easy_lausanne on the
template. See

  https://github.com/mattcieslak/easy_lausanne

Some additional dilation was done to convert the surface into a more dense
parcellation of the cortex in the template volume. Details below.

---

The output from easy_lausanne:

  ROIv_scale[33 60 125 250 500]_dilated.nii.gz

This is the Lausanne output in the T1 space, after additional dilation with
atlas_dilate.

Mask with template GM. The template cortical mask is derived from the JLF DKT
parcellation. 

for i in 33 60 125 250 500; do 
  c3d T_template0_CorticalMask.nii.gz ROIv_scale${i}_dilated.nii.gz -multiply -o maskedGM/ROIv_scale${i}_masked.nii.gz
done

Then remove the subcortical labels explicitly (just to make sure there aren't errant voxels):

c3d maskedGM/ROIv_scale33_masked.nii.gz -replace 35 0 36 0 37 0 38 0 39 0 40 0 41 0 76 0 77 0 78 0 79 0 80 0 81 0 82 0 83 0 -o maskedFinal/Lausanne_Scale33.nii.gz

c3d maskedGM/ROIv_scale60_masked.nii.gz -replace 58 0 59 0 60 0 61 0 62 0 63 0 64 0 122 0 123 0 124 0 125 0 126 0 127 0 128 0 129 0 -o maskedFinal/Lausanne_Scale60.nii.gz

c3d maskedGM/ROIv_scale125_masked.nii.gz -replace 109 0 110 0 111 0 112 0 113 0 114 0 115 0 227 0 228 0 229 0 230 0 231 0 232 0 233 0 234 0 -o maskedFinal/Lausanne_Scale125.nii.gz

c3d maskedGM/ROIv_scale250_masked.nii.gz -replace 224 0 225 0 226 0 227 0 228 0 229 0 230 0 456 0 457 0 458 0 459 0 460 0 461 0 462 0 463 0 -o maskedFinal/Lausanne_Scale250.nii.gz

# For scale 500, not included here
# c3d maskedGM/ROIv_scale500_masked.nii.gz -replace 502 0 503 0 504 0 505 0 506 0 507 0 508 0 1008 0 1009 0 1010 0 1011 0 1012 0 1013 0 1014 0 1015 0 -o maskedFinal/Lausanne_Scale500.nii.gz

