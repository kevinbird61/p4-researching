#!/bin/bash

# running the "beacon scenario"
simple_switch_CLI --thrift-port 9090 < cli/s1/beacon.txt
simple_switch_CLI --thrift-port 9093 < cli/s4/beacon.txt
simple_switch_CLI --thrift-port 9094 < cli/s5/beacon.txt