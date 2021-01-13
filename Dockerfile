FROM ubuntu:bionic-20200713 as builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    software-properties-common \
                    build-essential \
                    apt-transport-https \
                    ca-certificates \
                    gnupg \
                    software-properties-common \
                    wget \
                    ninja-build \
                    git \
                    zlib1g-dev

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
    | apt-key add - \
  && apt-add-repository -y 'deb https://apt.kitware.com/ubuntu/ xenial main' \
  && apt-get update \
  && apt-get -y install cmake=3.18.3-0kitware1 cmake-data=3.18.3-0kitware1

RUN mkdir -p /tmp/ants/src \
    && git clone https://github.com/ANTsX/ANTs.git /tmp/ants/src \
    && cd /tmp/ants/src \ 
    && git checkout v2.3.5 \
    && mkdir -p /tmp/ants/build \
    && cd /tmp/ants/build \
    && mkdir -p /opt/ants \
    && git config --global url."https://".insteadOf git:// \
    && cmake \
      -GNinja \
      -DBUILD_TESTING=OFF \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_PREFIX=/opt/ants \
      /tmp/ants/src \
    && cmake --build . --parallel \
    && cd ANTS-build \
    && cmake --install .

FROM ubuntu:bionic-20200713
COPY --from=builder /opt/ants /opt/ants
COPY --from=pyushkevich/itksnap:latest /usr/local/bin/c3d /opt/bin/c3d

RUN apt-get update \
    && apt install -y --no-install-recommends zlib1g-dev \
    && apt install -y --no-install-recommends zlib1g-dev \
    && apt install -y python3.7 python-pip \
    && pip install setuptools \
    && pip install pybids \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV ANTSPATH="/opt/ants/bin/" \
    PATH="/opt/bin:/opt/scripts:/opt/ants/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

RUN mkdir -p /opt/scripts
COPY runAntsCT_nonBIDS.pl /opt/scripts/runAntsCT_nonBIDS.pl
COPY trim_neck.sh /opt/scripts/trim_neck.sh
# BIDS script when it's ready to use 
# COPY runANTsCT.py /opt/scripts/runANTsCT.py
COPY template /opt/template
RUN chmod a+x /opt/scripts/*

WORKDIR /data

# Default entrypoint will be for BIDS 
# User can override for legacy compatibility
#
# ENTRYPOINT ["/opt/scripts/runANTsCT.py"]
#
# For now, use a legacy interface
ENTRYPOINT ["/opt/scripts/runAntsCT_nonBIDS.pl"]
