sudo simple_switch \
    -i 1@s1-eth1 \
    -i 2@s1-eth2 \
    -i 3@s1-eth3 \
    -i 4@s1-eth4 \
    --pcap --thrift-port 9090 \
    --nanolog ipc:///tmp/bm-0-log.ipc \
    --device-id 0 \
    target.json \
    --log-console