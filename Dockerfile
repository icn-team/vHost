FROM ubuntu:18.04

# Install amin packages
RUN apt-get update \
 && apt-get install -y curl cmake build-essential

# Install sysrepo + dependencies
RUN curl -OL https://github.com/muscariello/build-scripts/raw/master/deb/libyang_0.16-r2_amd64.deb \
 && curl -OL https://github.com/muscariello/build-scripts/raw/master/deb/sysrepo_0.7.7_amd64.deb \
 && curl -OL https://github.com/muscariello/build-scripts/raw/master/deb/libnetconf2_0.12-r1_amd64.deb \
 && curl -OL https://github.com/muscariello/build-scripts/raw/master/deb/netopeer2_0.7-r1_amd64.deb \
 && curl -OL https://jenkins.fd.io/job/hicn-sysrepo-plugin-verify-master/lastSuccessfulBuild/artifact/scripts/build/hicn_sysrepo_plugin-19.01-112-release-Linux.deb
RUN apt-get install -y ./libyang_0.16-r2_amd64.deb ./sysrepo_0.7.7_amd64.deb \
                       ./libnetconf2_0.12-r1_amd64.deb ./netopeer2_0.7-r1_amd64.deb

# Install sysrepo hicn plugin
RUN apt-get install -y ./hicn_sysrepo_plugin-19.01-112-release-Linux.deb --no-install-recommends
 
# Build hicn suite (from source for disabling punting)
WORKDIR /hicn
RUN git clone https://github.com/FDio/hicn.git \
 && mkdir build && cd build \
 && cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_PUNTING=OFF -DBUILD_APPS=ON \
 && make -j4 install

# Clean up
RUN apt-get remove -y curl cmake build-essential \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get autoremove -y \
 && apt-get clean
