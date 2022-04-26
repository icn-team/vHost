FROM ubuntu:20.04

# Use bash shell
SHELL ["/bin/bash", "-c"]

RUN apt-get update
RUN apt-get install -y curl

RUN curl -s https://packagecloud.io/install/repositories/fdio/2202/script.deb.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/fdio/hicn/script.deb.sh | bash

RUN apt-get install -y hicn-apps hicn-light facemgr hicn-plugin vpp vpp-plugin-core

CMD ["/usr/bin/hicn-light-daemon"]
