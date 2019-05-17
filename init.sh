#!/bin/bash

VETH=($(ip link show | grep mtu | awk '{print $2}' | awk '{$0=substr($0,1,length($0)-1); print $0}' | awk -F '@' {'print $1'}))

for i in "${VETH[@]}"
do
    if [[ $i == *"eth"* ]]
    then
        ethtool -K $i tx off rx off ufo off gso off gro off tso off
 fi
done
hicn-light-daemon --config /etc/hicn/startup1.exec --port 9695 --log-file /tmp/hicn_light.log --capacity 1000 &
sleep 2
sysrepod
sysrepo-plugind
netopeer2-server
trap "kill -9 $$" SIGHUP SIGINT SIGTERM SIGCHLD
wait
