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

# About this repository

* Learning how to write a P4 program by [basic example](src/basic).
* Learning how to make a P4Runtime controller(I called it simple-monitor) by [simple example](src/simple-monitor).
* Learning how to use a P4Runtime controller:
    * From [example of p4lang/tutorials - p4runtime](src/p4runtime).
    * From [advance usage(larger topo, modify/delete table entries support) of controller](src/advance-topo).
* Learning how to use In-band Network Telemetry (`WIP`)

# Author

National Cheng Kung University, 瞿旭民 (Kevin Cyu), kevinbird61@gmail.com

# Reference

* [p4.org - P4_16 Spec - v1.0.0](https://p4.org/p4-spec/docs/P4-16-v1.0.0-spec.html)
* [p4.org - P4 PSA Spec - v1.0.0](https://p4.org/p4-spec/docs/PSA-v1.0.0.html)
* [p4.org - P4Runtime Spec - v1.0.0](https://p4.org/p4-spec/docs/P4Runtime-v1.0.0.pdf)
* [p4.org - In-band Network Telemetry(INT) Dataplane Specification](https://github.com/p4lang/p4-applications/blob/master/docs/INT.pdf)
* [p4.org - Telemetry Report Format Specification](https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report.pdf)
* [p4lang/tutorials](https://github.com/p4lang/tutorials)
* [p4lang/p4factory/apps/int](https://github.com/p4lang/p4factory/tree/master/apps/int)
