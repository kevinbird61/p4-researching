# Network Topology Construction

當你不想使用 mininet 作為建立網路拓僕的手段時，可以利用、參考這裡的腳本，了解並使用 linux virtual networking 的強大！

* 搭配的呼叫 P4 software switch 來做使用：
```
# create 1 switch for those virtual hosts
sudo simple_switch \
    -i 1@s1-eth1 \
    -i 2@s1-eth2 \
    -i 3@s1-eth3 \
    -i 4@s1-eth4 \
    --pcap \
    --thrift-port 9090 \
    --nanolog ipc:///tmp/bm-0-log.ipc \
    --device-id 0 \
    <your_p4_program_compiled_result>.json \
    --log-console
```