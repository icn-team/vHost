FROM ubuntu:18.04

# Build hicn suite (from source for disabling punting)
WORKDIR /hicn

# Install main packages
RUN apt-get update \
  && apt-get install -y curl git cmake build-essential

# Build libyang from source
# Install dependencies
################################################
RUN apt-get -y install libpcre3-dev swig
               
RUN git clone https://github.com/CESNET/libyang
RUN mkdir -p libyang/build && pushd libyang/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr ..
RUN make -j 4 install
RUN popd
################################################

# Build sysrepo from source
########################################################################################
RUN apt-get -y install libprotobuf-c1-dev libev-dev libavl-dev protobuf-c-compiler

RUN git clone https://github.com/sysrepo/sysrepo.git
RUN mkdir -p sysrepo/build && pushd sysrepo/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr ..
RUN make -j 4 install
RUN popd
########################################################################################

# Build libnetconf2 from source
############################################################
RUN git clone https://github.com/CESNET/libnetconf2
RUN mkdir -p libnetconf2/build && pushd libnetconf2/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr ..
RUN make -j 4 install
RUN popd
############################################################

# Build Netopeer
#####################################################################
RUN git clone https://github.com/CESNET/Netopeer2
RUN mkdir -p Netopeer2/server/build && pushd Netopeer2/server/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr ..
RUN make -j 4 install
RUN popd
#####################################################################


# Download sysrepo plugin
RUN curl -OL https://jenkins.fd.io/job/hicn-sysrepo-plugin-verify-master/lastSuccessfulBuild/artifact/scripts/build/hicn_sysrepo_plugin-19.01-176-release-Linux.deb

# Install sysrepo hicn plugin
RUN apt-get install -y ./hicn_sysrepo_plugin-19.01-176-release-Linux.deb --no-install-recommends

# Install hicn dependencies
RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
RUN apt-get install -y libparc-dev libasio-dev libcurl4-openssl-dev --no-install-recommends

RUN git clone https://github.com/FDio/hicn.git \
  && mkdir build && cd build \
  && cmake ../hicn -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_PUNTING=OFF -DBUILD_APPS=OFF \
  && make -j4 install

# Clean up
RUN apt-get remove -y curl git cmake build-essential libasio-dev libcurl4-openssl-dev \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove -y \
  && apt-get clean

WORKDIR /

RUN rm -r /hicn