# Utiltiy of p4-reasearching project

> Using the utility concept & some source code from [`p4lang/tutorials`](https://github.com/p4lang/tutorials). All right preserved by p4lang organization.

## Hierarchy
* p4runtime_lib/
   * switch.py
   * helper.py
   * bmv2.py
   * convert.py
   * simple_controller.py
* p4_mininet.py (`P4Host`,`P4Switch`,`P4RuntimeSwitch(Merge from p4runtime_switch.py)`)
* netstat.py
* run_exercise.py (Run and construct network topology from specified json file.)

---

## Functional
* `switch.py`
    * switch connection, using gRPC to connect with P4Switch target device
    * Provide `Read/Write` TableEntry
    * **Modified:**
      * Add function `ModifyTableEntry`, `DeleteTableEntry`.
* `helper.py`
    * `Build` TableEntry
    * Parse P4Info (using `convert.py`)
* `bmv2.py`
    * Let target device to load the P4 Program (using the switch connection provided by `switch.py`)
* `convert.py`
    * used by `helper.py`
    * Transform the data format (From programmer, `Human-readable string` <=> `P4Info string`)
---
## Process

這部份分析 run_exercise.py (由 p4lang/tutorials 內提供) 如何建立一個 P4 的實驗環境。
1. 指定必要參數
    1. topology 的 json 程式
    2. 編譯 P4 後產生的程式
    3. 指定 software switch 的運行目標，example: `simple_switch_grpc`
2. 執行 `ExerciseRunner` 的 class 初始化
    1. 這部份主要是做整個系統初始化用、包括讀 topology 檔、建 hosts, links 等等
3. 執行 `ExerciseRunner` 內的 function - `run_exercise()`
    1. `create_network()` 
        1. 設置 Mininet Object，創建屬性 `.net` 以及 `.topo`，並且 `.topo` 透過 `ExerciseTopo` 的 class 來做創建
    2. 呼叫 `.net.start()`
        1. 啟動方才建立的 Mininet Object 之中 `.net`
    3. `program_hosts()`
        1. 為 hosts 做初始化
    4. `program_switches()`
        1. 設置每一個 switch
    5. `do_net_cli()`
        1. 完成 config, 打印 log 訊息後進入 mininet CLI 模式，開始進行操作
        
