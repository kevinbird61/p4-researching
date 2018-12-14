#!/bin/sh
#
# Build the topology using TCLink on Mininet and connect with remote controller
# AUTHOR: David Lu (https://github.com/yungshenglu)

mn --custom topo.py --topo topo --link tc --controller remote