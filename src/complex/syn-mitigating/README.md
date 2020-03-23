# SYN Mitigating
## 簡介
  嘗試在SDN的架構下偵測與防禦SYN Flooding，並利用P4的特性來實做與優化我們的方法。
## 執行方式
### 直接執行
1. 開啟mininet環境
```
sudo ./build.sh    
```
2. 看到"please open controller"後才打開controller

```
sudo python2 p4_controller.py    
```
### 修改攻擊流量
請到下面這個位置修改mininet開啟後所執行的指令
```
cd ../../../utils/syn_exercise.py
```
## TOPO
https://raw.githubusercontent.com/ting2313/p4-researching/master/src/complex/syn-mitigating/pic/topo.png
## 流程圖
https://raw.githubusercontent.com/ting2313/p4-researching/master/src/complex/syn-mitigating/pic/flow.png

## 相關Project
### 實做於OF的版本（由ArielWu0203撰寫）
https://github.com/ArielWu0203/Net_Project

## TODO
1. 減少無辜被影響的範圍
2. 處理controller可能被攻擊的狀況
