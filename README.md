# p4-researching
My Researching work on P4.

> Notice: Current testing environment are not based on the latest version of P4.
>           You can using the scripts under `docker/` to build a docker image for these tests.
> And all the examinations are running on software switch, a.k.a "bmv2", and I use `simple_switch_grpc` as demonstration.
> 

# Environment Setting

* Build sucessfully with `Ubuntu 16.04`:
    * [Installation script - P4](https://github.com/toolbuddy/ssfw#p4-environment-setup)
    * [Installation script - ONOS](https://github.com/toolbuddy/ssfw#onos-installation)
* Also you can build your own test environment in docker
    * [Installation for Docker](https://github.com/toolbuddy/ssfw#docker-installation)
    * [Build your own P4 testbed](docker/)

---

# About this repository

## P4 (with `Mininet`)
* Learning how to write a P4 program by [basic example](src/basic).
* Learning how to make a P4Runtime controller(I called it simple-monitor) by [simple example](src/simple-monitor).
* Learning how to use a P4Runtime controller:
    * From [example of p4lang/tutorials - p4runtime](src/advance-tunnel).
    * From [advance usage(larger topo, modify/delete table entries support) of controller](src/advance-topo).
* Learning how to use [In-band Network Telemetry (`WIP`)](src/int)
    * Using `psa.p4`(Can't compiled)/`v1model.p4`(Compiled, but not tested) architecture to construct transit/sink target device.
* Learning how to implement NAT 
    * Simple NAT forward/reverse [example](src/simple-nat)
    * More complicated (`WIP`)
* Learning how to implement MPLS
    * MPLS [example](src/mpls)
* Learning how to implement broadcast 
    * bcast [example](src/bcast)
* Learning how to use register
    * register [example](src/register)
    * table-array [example](src/table-entry)
* Learning how to use meter
    * meter [example](src/meter)

> You can found some tutorials in [`branch:tutorials`](https://github.com/kevinbird61/p4-researching/tree/tutorials)

## P4 with ONOS

Learning how to build an ONOS application which support P4.

---

# Author

National Cheng Kung University, 瞿旭民 (Kevin Cyu), kevinbird61@gmail.com

* [DigitalOcean - Hsinchu: Learning P4 from example (slides)](https://docs.google.com/presentation/d/15NPJ3wnYTEr_La7Ny-n2Q8SLTVFJhv5rDmB2Alku3z0/edit?usp=sharing)

---

# Reference

* [p4.org - P4_16 Spec - v1.0.0](https://p4.org/p4-spec/docs/P4-16-v1.0.0-spec.html)
* [p4.org - P4 PSA Spec - v1.0.0](https://p4.org/p4-spec/docs/PSA-v1.0.0.html)
    * [v1model.p4](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)
    * [psa.p4](https://github.com/p4lang/p4c/blob/master/p4include/psa.p4)
* [p4.org - P4Runtime Spec - v1.0.0](https://p4.org/p4-spec/docs/P4Runtime-v1.0.0.pdf)
    * [v1/p4runtime.proto](https://github.com/p4lang/p4runtime/blob/master/proto/p4/v1/p4runtime.proto)
    * [v1/p4data.proto](https://github.com/p4lang/p4runtime/blob/master/proto/p4/v1/p4data.proto)
    * [config/v1/p4info.proto](https://github.com/p4lang/p4runtime/blob/master/proto/p4/config/v1/p4info.proto)
    * [config/v1/p4types.proto](https://github.com/p4lang/p4runtime/blob/master/proto/p4/config/v1/p4types.proto)
    > Notice: Latest P4Runtime have updated to `v1`, this repository can't be compiled/run under `v1` environment.
* [p4.org - In-band Network Telemetry(INT) Dataplane Specification](https://github.com/p4lang/p4-applications/blob/master/docs/INT.pdf)
* [p4.org - Telemetry Report Format Specification](https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report.pdf)
* [p4lang/tutorials](https://github.com/p4lang/tutorials)
* [p4lang/p4factory/apps/int](https://github.com/p4lang/p4factory/tree/master/apps/int)
