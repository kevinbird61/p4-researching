#!/bin/bash

# running the "protected scenario", a.k.a Firewall
simple_switch_CLI --thrift-port 9090 < cli/s1/protected.txt
simple_switch_CLI --thrift-port 9092 < cli/s3/protected.txt
simple_switch_CLI --thrift-port 9094 < cli/s5/protected.txt