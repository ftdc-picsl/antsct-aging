# antsct-aging

ANTs cortical thickness pipeline container, contains a template for older
individuals.

By default, the `trim_neck.sh` script is called to crop the input image to
remove the neck region, users may optionally mask the neck region with zeros, or
proceed with the unaltered input image.

The template is provided by Nick Tustison.

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


## References

For ANTs cortical thickness: [Tustison, et al 2014](http://dx.doi.org/10.1016/j.neuroimage.2014.05.044).

For c3d: [Yushkevich, et al 2006](http://dx.doi.org/10.1016/j.neuroimage.2006.01.015).
