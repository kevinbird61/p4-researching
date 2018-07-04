# simple controller

製作簡易的 controller 為目的，搭配原有 p4lang/tutorials 提供的 p4 + mininet 相關程式碼來做練習。

## Scenario

* Topology
    * 透過 `topology.json` 來定義網路拓樸的模樣
    * 採用3個 switch 互相連接彼此，並各自對應一個 end host
        * s1, s2, s3
        * h1, h2, h3
* P4 program
    * 使用基本的 l3_forwarding 的 P4 程式碼
    * 並在封包完成 ipv4_forward 後對 counter 來做累加
* Controller
    * 使用根目錄下 utils/ 提供的 p4 + mininet 程式來製作
    * 提供基本的幾個動作，於本專案提供：
        * 寫入簡單規則: 取代 `basic/` 內原本給 switch 讀取的 sx-runtime.json，改由 controller 做派送。
        * 使用簡單的 counter 操作，了解 counter 當中 counter name 與 index 間關係、以及 counter 的簡單使用方法。


