FROM ubuntu:18.04 as intermediate

WORKDIR /hicn-build

# Use bash shell
SHELL ["/bin/bash", "-c"]

RUN apt-get update
RUN apt-get install -y git ssh curl

# Clone the repos
COPY . ./hproxy
RUN git clone https://github.com/FDio/hicn.git

RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/fdio/hicn/script.deb.sh | bash

# Install main packages
RUN apt-get install -y cmake libparc-dev libconfig-dev build-essential libasio-dev --no-install-recommends

RUN mkdir build-hicn
WORKDIR /hicn-build/build-hicn
RUN cmake -DCMAKE_INSTALL_PREFIX=/hicn-root -DENABLE_PUNTING=OFF ../hicn
RUN make -j4 install

###################################################
# Clean up
###################################################

FROM ubuntu:18.04
RUN apt-get update && apt-get install -y curl \
    && curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh  | bash \
    && apt-get install -y iproute2 libparc --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean

COPY --from=intermediate /hicn-root /hicn-root

WORKDIR /
