#!/bin/bash

# running the "normal scenario"
simple_switch_CLI --thrift-port 9090 < cli/s1/normal.txt
simple_switch_CLI --thrift-port 9091 < cli/s2/normal.txt
simple_switch_CLI --thrift-port 9094 < cli/s5/normal.txt