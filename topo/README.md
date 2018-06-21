# Mininet Network Topology

> Using the utility concept from `p4lang/tutorials`

## Hierarchy
* topo/
    * p4runtime_lib/
        * p4_mininet.py (`P4Host`,`P4Switch`,`P4RuntimeSwitch`)
        * netstat.py
    * switch.py
    * helper.py
    * bmv2.py
    * convert.py
    * build_topo.py (main program)

## Functional

* `switch.py`
    * switch connection, using gRPC to connect with P4Switch target device
    * Provide `Read/Write` TableEntry
* `helper.py`
    * `Build` TableEntry
    * Parse P4Info (using `convert.py`)
* `bmv2.py`
    * Let target device to load the P4 Program (using the switch connection provided by `switch.py`)
* `convert.py`
    * used by `helper.py`
    * Transform the data format (From programmer, `Human-readable string` <=> `P4Info string`)
