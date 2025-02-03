# antsct-aging

[![Docker
Pulls](https://img.shields.io/docker/pulls/cookpa/antsct-aging.svg)](https://hub.docker.com/repository/docker/cookpa/antsct-aging)

ANTs cortical thickness pipeline container, contains a template for older
individuals.

By default, the `trim_neck.sh` script is called to crop the input image to
remove the neck region, users may optionally mask the neck region with zeros, or
proceed with the unaltered input image.

The template is provided by Nick Tustison, as described in the longitudinal paper (see
references below)

Cortical labels are warped to the subject space after processing, label
information and definitions are under template/labels.

A warp between the internal template and the MNI152NLin2009cAsym template is
downloaded at build time and included in the container. This is used to warp
labels from MNI152NLin2009cAsym space to subject space through the internal
template. Users may additionally specify their own labels in the
MNI152NLin2009cAsym space.


## Container images

Download Docker images from [DockerHub](https://hub.docker.com/repository/docker/cookpa/antsct-aging/general).

To build a Singularity image,

```
sudo singularity build antsct-aging-tag.sif docker://cookpa/antsct-aging:tag
```

where "tag" is the version you want to build, or "latest" to get the latest version.


## Included software

ANTs cortical thickness is part of [ANTs](https://github.com/ANTsX/ANTs).

The trim_neck.sh is provided by Paul Yushkevich and Sandhitsu Das, and uses
[c3d](https://github.com/pyushkevich/c3d).


## Brain labels

Please see the individual label directories under the template directory for
label information including citations and licensing terms.

Custom labels defined at run time must be aligned to the MNI152NLin2009cAsym
template in templateflow v1.4.1.

### Cortical label propagation

Cortical labels are propagated to the thickness mask after being warped to the subject
space. This tries to ensure that cortical GM is not left unlabeled because of registration
error.

### Subcortical areas labeled as cortical GM

The original ANTsCT templates label the amygdala and hippocampus as cortical GM. This
means propagated labels must include these areas. Prior to antsct-aging 0.6.0, the
built-in labels did not include these areas, which leads to inaccurate label propagation
in the temporal lobe. Only "Cortical" labels or labels passed with the
`--mni-cortical-labels` were affected.

Starting from antsct-aging 0.6.0, the template labels have been updated to temporarily
include BrainCOLOR amygdala and hippocampus. This should reduce problems, but it's
possible that mislabeling may still occur as a result of registration or segmentation
error, so QC of labels is still important.

Thickness in medial temporal labels adjacent to the amygdala and hippocampus, notably
parahippocampal and entorhinal cortex, may still be less reliable because even though the
label propagation algorithm is fixed, the underlying thickness computation is still the
same. We recommend using a dedicated segmentation tool for these areas, such as ASHS.


### QC of cortical labels

To assist QC, the "WarpedVsPropagated" statistics have been changed in v0.6.0, we now
output "WarpedVsMasked" and "MaskedVsPropagated" statistics. This makes it clearer how
much the labels change with each processing step.

The label propagation implicitly includes masking since no labels are propagated outside
the thickness mask. The "MaskedVsPropagated" stats therefore show how much the labels
change by the propagation adding labels to unlabeled GM voxels. The "WarpedVsMasked" show
how much the labels change by removing labeled voxels outside the subject's GM
segmentation.


## Running the container

```
# For cross-sectional processing
docker run --rm -it cookpa/antsct-aging:0.6.0 --help

# For longitudinal processing
docker run --rm -it cookpa/antsct-aging:0.6.0 --help --longitudinal
```

## References

For ANTs cortical thickness: [Tustison, et al 2014](http://dx.doi.org/10.1016/j.neuroimage.2014.05.044).

For ANTs longitudinal cortical thickness: [Tustison, et al 2019](https://doi.org/10.3233/JAD-190283)

For c3d: [Yushkevich, et al 2006](http://dx.doi.org/10.1016/j.neuroimage.2006.01.015).
