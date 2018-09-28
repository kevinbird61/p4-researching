#!/bin/bash
# Print script commands.
set -x
# Exit on errors.
set -e

GRPC_COMMIT="v1.3.2"
NUM_CORES=`grep -c ^processor /proc/cpuinfo`

# gRPC
git clone https://github.com/grpc/grpc.git
cd grpc
git checkout ${GRPC_COMMIT}
git submodule update --init --recursive
export LDFLAGS="-Wl,-s"
make -j${NUM_CORES}
sudo make install
sudo ldconfig
unset LDFLAGS
cd ..
# Install gRPC Python Package
sudo -H pip install grpcio cffi scapy ipaddr psutil