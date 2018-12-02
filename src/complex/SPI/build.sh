#!/bin/sh

# Step 1: Create *.json and *.p4info
make

# Step 2: Assign those deps to ../../lib/main.py
#       - topology.json
#       - *.p4.json
#       - "simple_switch_grpc"
sudo python ../../../utils/run_exercise.py \
    --topo topology.json \
    --switch_json basic_tutorial_switch.json \
    --behavioral-exe simple_switch_grpc