FROM ubuntu:18.04

# Build hicn suite (from source for disabling punting)
WORKDIR /hicn
ENV SYSREPO_PLUGIN_DEB=hicn_sysrepo_plugin-19.04-15-release-Linux.deb
ENV SYSREPO_PLUGIN_URL=https://jenkins.fd.io/job/hicn-sysrepo-plugin-verify-master/48/artifact/scripts/build/${SYSREPO_PLUGIN_DEB}
ENV HICN_PLUGIN_LIB=/usr/lib/x86_64-linux-gnu/sysrepo/plugins/libhicn.so
ENV TRANSPORT=HICN

# Use bash shell
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y curl
RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash

# Install main packages
RUN apt-get install -y git cmake build-essential libpcre3-dev swig                              \
    libprotobuf-c-dev libev-dev libavl-dev protobuf-c-compiler libssl-dev                       \
    libssh-dev libcurl4-openssl-dev libasio-dev libparc-dev                                     \
    ffmpeg libxml2 ffmpeg libxml2-dev qt5-default libqtav-dev libqt5svg5-dev                    \
    libqt5charts5-dev qtmultimedia5-dev qtdeclarative5-dev --no-install-recommends              \
    libavcodec-dev libavutil-dev libavformat-dev;                                               \
  # Install hicn dependencies                                                                   \
  rm -rf /var/lib/apt/lists/*                                                                   \
  ###############################################                                               \
  # Build libyang from source                                                                   \
  ################################################                                              \
  && git clone https://github.com/CESNET/libyang                                                \
  && mkdir -p libyang/build                                                                     \
  && pushd libyang/build && cmake -DCMAKE_INSTALL_PREFIX=/usr .. && make -j 4 install && popd   \
  ########################################################################################      \
  # Build sysrepo from source                                                                   \
  ########################################################################################      \
  && git clone https://github.com/sysrepo/sysrepo.git                                           \
  && mkdir -p sysrepo/build                                                                     \
  && pushd sysrepo/build && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr ..     \
  && make -j 4 install && popd                                                                  \
  ############################################################                                  \
  # Build libnetconf2 from source                                                               \
  ############################################################                                  \
  && git clone https://github.com/CESNET/libnetconf2                                            \
  && mkdir -p libnetconf2/build                                                                 \
  && pushd libnetconf2/build && cmake -DCMAKE_INSTALL_PREFIX=/usr .. && make -j4 install && popd\
  ############################################################                                  \
  # Build Netopeer                                                                              \
  ############################################################                                  \
  && git clone https://github.com/CESNET/Netopeer2                                              \
  && mkdir -p Netopeer2/server/build                                                            \
  && pushd Netopeer2/server/build && cmake -DCMAKE_INSTALL_PREFIX=/usr ..                       \
  && make -j 4 install && popd                                                                  \
  #####################################################################                         \
  # Download sysrepo plugin                                                                     \
  && curl -OL ${SYSREPO_PLUGIN_URL}                                                             \
  # Install sysrepo hicn plugin                                                                 \
  && apt-get install -y ./${SYSREPO_PLUGIN_DEB} --no-install-recommends \
  ###################################################                                           \
  # Build hicn suite from source                                                                \
  ###################################################                                           \
  && git clone https://github.com/FDio/hicn.git                                                 \
  && mkdir build && pushd build                                                                 \
  && cmake ../hicn -DENABLE_PUNTING=OFF                                                         \
  && make -j4 install && popd                                                                   \
  ###################################################                                           \
  # Build viper from source                                                                     \
  ###################################################                                           \
  ### Temporary fix for the always_inline incompatibility with QT                               \
  && sed -i 's/#define always_inline static inline/#define always_inline inline/g' /usr/local/include/hicn/common.h\
  && git clone -b viper/master https://gerrit.fd.io/r/cicn viper                                \
  && pushd viper/libdash                                                                        \
  && mkdir build && pushd build                                                                 \
  && cmake ../ -DCMAKE_INSTALL_PREFIX=/usr/local                                                \
  && make && make install                                                                       \
  && popd && popd                                                                               \
  && cd viper                                                                                   \
  && mkdir build && cd build                                                                    \
  && qmake ../viper.pro "TRANSRPOT_LIBRARY = HICNET"                                            \
  && make install                                                                               \
  ###################################################                                           \
  # Clean up                                                                                    \
  ###################################################                                           \
  && apt-get remove -y curl git cmake build-essential libasio-dev                               \
                      libcurl4-openssl-dev libev-dev libevent-dev                               \
                      libparc-dev libpcre3-dev libprotobuf-c-dev                                \
                      libssh-dev libssl-dev protobuf-c-compiler swig                            \
  && apt-get install libprotobuf-c1 libev4                                                      \
  && rm -rf /var/lib/apt/lists/*                                                                \
  && apt-get autoremove -y                                                                      \
  && apt-get clean && rm -r /hicn                                                               \
  ####################################################                                          \
  # Delete library for hicn-plugin                                                              \
  ####################################################                                          \
  && rm ${HICN_PLUGIN_LIB}
WORKDIR /