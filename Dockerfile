FROM ubuntu:18.04

RUN apt-get update && apt-get install -y curl git build-essential libasio-dev libcurl4-openssl-dev cmake

# Install hicn dependencies
RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
RUN apt-get install -y cmake build-essential libparc-dev libasio-dev libcurl4-openssl-dev --no-install-recommends
 
# Build hicn suite (from source for disabling punting)
WORKDIR /hicn
RUN git clone https://github.com/FDio/hicn.git \
 && mkdir build && cd build \
 && cmake ../hicn -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_PUNTING=OFF -DBUILD_APPS=ON \
 && make -j4 install

# Clean up
RUN apt-get remove -y cmake build-essential libasio-dev libcurl4-openssl-dev curl \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get autoremove -y \
 && apt-get clean

RUN rm -r /hicn

CMD ["/usr/bin/hicn-light-daemon"]
