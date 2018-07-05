# advance

製作簡易的 controller 為目的，搭配原有 p4lang/tutorials 提供的 p4 + mininet 相關程式碼來做練習。

## Scenario

* Topology
    * 透過 `topology.json` 來定義網路拓樸的模樣
    * 採用較大型的網路架構
* P4 program
    * 使用基本的 l3_forwarding 的 P4 程式碼，額外加上 tcp/udp 支援
    * 並在封包完成 `ipv4_forward`、`tcp/udp_forward` 後對不同 counter 來做累加
* Controller
    * 使用根目錄下 utils/ 提供的 p4 + mininet 程式來製作
    * 提供基本的幾個動作，於本專案提供：
        * 寫入簡單規則: 取代 `basic/` 內原本給 switch 讀取的 sx-runtime.json，改由 controller 做派送。
        * 使用簡單的 counter 操作，了解 counter 當中 counter name 與 index 間關係、以及 counter 的簡單使用方法。
        * 在 controller 端做判斷，當 counter 數量超過某一個定值，則導到另一條 path
---

## Run 

* Step 1: `./build.sh` 啟動 mininet 環境
   * 載入編寫的 p4 program (.json) 以及依據拓樸 (topology.json) 來建制 mininet 
* Step 2: `make controller` 來啟動 controller
   * 開啟 controller 後，會幫每台 switch 載入 forwarding rules 
   * 這麼一來連線功能就完成了
   
