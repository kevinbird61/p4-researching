#!/bin/bash
# Print script commands.
set -x
# Exit on errors.
set -e

# Mininet
git clone git://github.com/mininet/mininet mininet
cd mininet
sudo ./util/install.sh -nwv
cd ..