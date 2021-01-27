This directory contains labels in the MNI152NLin2009cAsym space. 

There is also a warp field to transform the labelse from the MNI152NLin2009cAsym
to the local template. The warp field is copied into the container at this
location at build time, because it's too large to store on Github. 

All templates and labels here come from templateflow 1.4.1.

--- Included labels ---

Schaefer labels with 7 networks and 100, 200, 400 regions are included with the
container.


--- template to MNI alignment --

The template to MNI warp was computed by registering 10 MICCAI 2012 challenge
brains to both templates, computing composite warps, and then averaging these to
make a consensus warp field.

For more details, see

https://figshare.com/account/projects/96092/articles/13542053

