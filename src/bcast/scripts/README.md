# 腳本使用 (simple_switch_CLI)

## 呼叫步驟

1. 呼叫 ./net_build.sh 建立 network namespace
2. 呼叫 make && ./bmv2.sh 編譯 P4 code 及啟動 simple_switch 連接這四個 host 
3. 呼叫 ./add_rules.sh 來透過 simple_switch_CLI 塞入 mc_group (broadcast, multicast 使用) 以及 rules 到 switch 上
4. 可以透過 tmux 開啟多個視窗來檢視各個 host: `ip netns exec hx /bin/bash --rcfile <(echo "PS1=\"namespace hx> \"")`，透過 `ip netns` 來執行 bash 並修改前缀信息方便檢視。
5. 一個視窗呼叫 python bcast_send.py，其餘三個都是呼叫 python bcast_listen.py，等待 sender broadcast 出去的封包。

這時候就能夠重現 mininet + simple_switch_grpc 的實驗。

## 清除

呼叫 ./clearall.sh 即可清除所有的 network namespace 
