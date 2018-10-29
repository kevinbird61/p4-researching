# Learning Switch

展示 learning switch 的範例。

## Goal

* 透過 packet-in/packet-out 來發現未知的 ports/packets、送到 controller 做處理後，加入所需的 rules 後來完成 switch 學習的過程

## Run 

* 透過 tmux 開啟兩個視窗後，各別開啟：
    * 運行的測試環境 - `./build.sh`: 運行 topology.json 內所示的網路拓樸後，進入 mininet CLI 後等待 controller 執行。
    * 執行 learn switch 的 P4 controller - `./start_p4_controller.sh`: 啟動 controller 後，回到上一步的 mininet CLI; 執行 `pingall` 或是 `h1 ping hx` 來檢視 P4 switch learning 的過程