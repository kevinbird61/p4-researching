# NAT

展示一個 NAT（網路位址轉換）的網路拓樸與 P4_16 的使用。

## Scenario

![](res/simple-nat.png)

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

* Step 1: `./build.sh` 啟動編譯、並開啟 mininet 環境
    * 使用 P4 程式以及依據拓樸來建置
* Step 2: `make controller` 來啟動 controller
    * 開啟 controller 後，會幫 NAT 以及一般的 switch 做上頭規則的填入

---

## 說明

* 這是一個極簡的 NAT 表達環境，由兩台 host、兩台 switch (1 NAT, 1 Normal switch) 構成
* 其中 h1 表達在 NAT 之後的 private 網路環境，而 h2 則表示具有 public IP 的伺服器
* 而 NAT (s1) 的功能主要在於幫助 h1 對外的 ip 轉換
    * 從原本的 private 的 ipv4 srcAddr `10.0.1.1` 轉成 NAT Public 的 `10.1.1.1`
    * 而對外進來的封包也要做改寫、並把目標 ipv4 dstAddr `10.1.1.1` 改回 `10.0.1.1`
    * 由於正式的 NAT 會需要建置一張 NAT Address mapping table，在這邊就先不做了
