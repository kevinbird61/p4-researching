# Meter 

實作 meter 功能，並用 iperf3 製造大流量，讓 meter 判斷 port 上的壅塞狀況，並用 MeterColor 來看是否執行 drop 

## Run 

* Step 1: `./build.sh` 啟動 mininet 環境
   * 載入編寫的 p4 program (.json) 以及依據拓樸 (topology.json) 來建制 mininet 
* Step 2: `make controller` 來啟動 controller
   * 開啟 controller 後，會幫每台 switch 載入 forwarding rules 
   * 這麼一來連線功能就完成了
   
## 觀察

* 進入 mininet CLI 後，透過 `xterm h1 h2` 開啟 h1, h2 的 terminal
* 在 h2 開始，開啟 server: `iperf3 -s` 
* 隨後到 h1 開啟 client: `iperf3 -c 10.0.2.2 -t 120 -i 5 -P 127 -M 300M` 來建立大量的流量到 h2
    * `-c <remote server IP>`: 連線到指定的遠端 server
    * `-t <second, e.g. 120>`: 測試時間，指定的數值為秒數
    * `-i <second>`: 幾秒輸出一次傳輸狀態
    * `-P <number>`: 同時建立多少連線，限制最大 128 條
    * `-M <number>M`: 傳輸的檔案大小，後面記得加個 M

* 前面兩個輸入後，回到 mininet CLI 上輸入 `h1 ping h2`，來觀察 `icmp_seq` 標號：

![](res/meter_screenshot.png)

可以看到， `icmp_seq` 的標號在 iperf3 運行時，出現缺號的狀況，即是被 meter.p4 給 drop 掉。

