This directory contains labels in the MNI152NLin2009cAsym space. 

There is also a warp field to transform the labels from the MNI152NLin2009cAsym
to the local template. The warp field is copied into the container at this
location at build time, because it's too large to store on Github. 

All templates and labels here come from templateflow 1.4.1.

--- Included labels ---

Schaefer labels with 7 networks and 100, 200, 400, and 500 regions are included
with the container.


--- template to MNI alignment --

The template to MNI warp was computed by registering 10 MICCAI 2012 challenge
atlas brains to both templates, then running a multi-channel registration to
align the atlases resampled into the two template spaces. 

For more details, see

https://doi.org/10.6084/m9.figshare.13542053.v2

