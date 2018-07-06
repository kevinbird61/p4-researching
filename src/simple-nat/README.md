# NAT

展示一個 NAT（網路位址轉換）的網路拓樸與 P4_16 的使用。

## Scenario

* Topology 
    * 採用上圖所示的網路拓樸
    * 與其他大多數的範例不同之處，在於 switch 上有分為一般的 switch，以及支援 NAT 的 switch
* P4 program
    * 一般 switch 使用 l3_forwarding 的程式
    * 而 NAT switch 則使用 nat.p4 來做 deploy
* Controller 
    * 與大部份的設置相同，不過因為 switch 不同的緣故，所以我們必須修改部份 controller 程式來使用

---

## Run

---

## 說明

