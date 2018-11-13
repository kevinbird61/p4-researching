# ECMP

Equal-cost multi-path routing, 又稱為 "等價多路徑路由"。

## Demo

![](res/ecmp.png)

## Monitor 

> p4runtime 由於 bmv2 目前還沒有 implement，所以沒有辦法使用。

使用的是 simple_switch_CLI，對 s1 做上頭 direct counter 的讀取。
```bash
➜  ECMP git:(master) ✗ simple_switch_CLI 
Obtaining JSON from switch...
Done
Control utility for runtime P4 table manipulation
RuntimeCmd: counter_read
counter_read
RuntimeCmd: counter_read
counter_read
RuntimeCmd: counter_read basic_tutorial_ingress.ecmp_table.ecmp_table_counter 0
this is the direct counter for table basic_tutorial_ingress.ecmp_table.ecmp_group
basic_tutorial_ingress.ecmp_table.ecmp_table_counter[0]=  BmCounterValue(packets=10, bytes=640)
```

上頭 RuntimeCmd 使用 index 來標示 direct counter 的 array index 