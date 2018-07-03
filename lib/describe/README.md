# 描述檔

* `*-runtime.json`
這部份針對每台 switch 上頭的設計而定，給予 switch 初步的設定狀態。
在目前支援的 table name 上，是採用該 control block 名稱作為前綴，再加上 table name 作為對外的 index 名稱。

* `topo.json`
另一方面則需要描述網路環境的檔案，一樣使用的是 json 來做描述，作為建立網路拓樸的依據。
