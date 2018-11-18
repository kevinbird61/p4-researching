#!/bin/sh

python ../../../utils/pktgen/sender.py -v 4 --ip 10.0.1.1 --loop 10 --msg "P4 is cool" --dport 1234 --sport 46000