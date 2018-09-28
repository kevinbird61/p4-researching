#!/bin/bash
# Print script commands.
set -x
# Exit on errors.
set -e

P4C_COMMIT="master"
NUM_CORES=`grep -c ^processor /proc/cpuinfo`

# P4C
git clone https://github.com/p4lang/p4c
cd p4c
git checkout ${P4C_COMMIT}
git submodule update --init --recursive
mkdir -p build
cd build
cmake ..
make -j${NUM_CORES}
make -j${NUM_CORES} check
sudo make install
sudo ldconfig
cd ..
cd ..

# Tutorial
sudo pip install crcmod