# p4-researching
My Researching work on P4.

> Notice: Current testing environment are not based on the latest version of P4.
>           You can using the scripts under `docker/` to build a docker image for these tests.
> And all the examinations are running on software switch, a.k.a "bmv2", and I use `simple_switch_grpc` as demonstration.
> 

# Environment Setting

Before getting started with P4 programming, we need a P4-capabled environment for running those scenario. And this repository summarize several methods and provide several way to accomplish.

* Build sucessfully with `Ubuntu 16.04.05`:
    * [Installation scripts - P4](install/)
    * [(Optional) Installation script - ONOS](https://github.com/toolbuddy/ssfw#onos-installation)
* Also you can build your own test environment in **docker**:
    * [Installation for Docker](https://github.com/toolbuddy/ssfw#docker-installation)
    * [Build your own P4 testbed with docker image](docker/)
* Using P4 virtual machine (via Oracle VirtualBox):
    * [`P4.ova` download](http://gofile.me/39GpL/Q4KZzrzTJ) : Completed P4 environment (Updated at: `2018/9/30`).
    * [`P4 (only with deps).ova` download](http://gofile.me/39GpL/3f01UDG0X) : For develop environment of P4-related tools.

---

# About this repository

## P4 (with `Mininet`)

* More details under [`src/`](src/)
* Contain lots of P4 practices and scenarios, which based on the open source software switch - BMv2 and mininet, with P4Runtime support to finish those work.

> Notice:
> 
> v0 users: You can found some tutorials in [`branch:tutorials`](https://github.com/kevinbird61/p4-researching/tree/tutorials)
> 
> v1 users: Use the master branch directly.

## P4 with ONOS
Learning how to build an ONOS application which support P4. See more detail under [`onos/`](onos/)

## Tracing P4Runtime
* Look [here](/res), have some diagram about P4Runtime's dependencies.

## Build network namespace
* If you don't want to use mininet, you can use `ip netns` instead.
* Under [`net/`](net/), have a demo script for building several network namespace.

## Learning Materials 
* Provide some learning resources about Networking, which located in [course/](course/).
* Welcome to contribute!

---

# Author

National Cheng Kung University, 瞿旭民 (Kevin Cyu), kevinbird61@gmail.com

## Activities
* (2018/09/12) DigitalOcean - Hsinchu: Learning P4 from example [(slide)](https://docs.google.com/presentation/d/15NPJ3wnYTEr_La7Ny-n2Q8SLTVFJhv5rDmB2Alku3z0/edit?usp=sharing), [(meetup.com)](https://www.meetup.com/DigitalOceanHsinchu/events/254314168/)
* (2018/12/08) SDN x Cloud Native Taiwan User Group - P4 Intro & Demonstration [(slide)](https://docs.google.com/presentation/d/1xHhrrWzsu3SawG2Zf1nZWs3_l3zHLWch9q04C1B4nog/edit?usp=sharing), [(kktix.com)](https://cntug.kktix.cc/events/sdn-cntug-12)

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
* [p4.org - In-band Network Telemetry(INT) Dataplane Specification](https://github.com/p4lang/p4-applications/blob/master/docs/INT.pdf)
* [p4.org - Telemetry Report Format Specification](https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report.pdf)
* [p4lang/tutorials](https://github.com/p4lang/tutorials)
* [p4lang/p4factory/apps/int](https://github.com/p4lang/p4factory/tree/master/apps/int)
