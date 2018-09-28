#!/bin/bash
# Print script commands.
set -x
# Exit on errors.
set -e

PROTOBUF_COMMIT="v3.2.0"
NUM_CORES=`grep -c ^processor /proc/cpuinfo`

# Protobuf
git clone https://github.com/google/protobuf.git
cd protobuf
git checkout ${PROTOBUF_COMMIT}
export CFLAGS="-Os"
export CXXFLAGS="-Os"
export LDFLAGS="-Wl,-s"
./autogen.sh
./configure --prefix=/usr
make -j${NUM_CORES}
sudo make install
sudo ldconfig
unset CFLAGS CXXFLAGS LDFLAGSi
# force install python module
cd python 
sudo python setup.py install
cd ../..