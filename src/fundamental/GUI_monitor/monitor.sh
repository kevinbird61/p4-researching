#!/bin/sh

sudo python ../../../utils/monitor.py \
    --p4info basic_tutorial_switch.p4info \
    --bmv2-json basic_tutorial_switch.json \
    --cnt-config counter_config.json
