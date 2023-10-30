FROM antsx/ants:v2.4.3

RUN apt-get update \
    && apt install -y wget \
    && apt install -y python3.7 python-pip \
    && pip install setuptools \
    && pip install pybids \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy the template from the source repo and download any extra data, eg warps
COPY template /opt/template
# Get MNI152 to template warp
RUN wget --directory-prefix /opt/template/MNI152NLin2009cAsym \
    --content-disposition https://ndownloader.figshare.com/files/26136116 2>/dev/null

COPY --from=pyushkevich/itksnap:latest /usr/local/bin/c3d /opt/bin/c3d

ENV ANTSPATH="/opt/ants/bin/" \
    PATH="/opt/bin:/opt/scripts:/opt/ants/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

RUN mkdir -p /opt/scripts
COPY run*.pl /opt/scripts/
COPY trim_neck.sh /opt/scripts/trim_neck.sh
# BIDS script when it's ready to use
# COPY runANTsCT.py /opt/scripts/runANTsCT.py

RUN chmod a+x /opt/scripts/*

WORKDIR /data

# Eventually the default entrypoint will be for BIDS data
# User can override for legacy compatibility
#
# ENTRYPOINT ["/opt/scripts/runANTsCT.py"]
#
# For now, use a legacy interface
ENTRYPOINT ["/opt/scripts/run.pl"]
