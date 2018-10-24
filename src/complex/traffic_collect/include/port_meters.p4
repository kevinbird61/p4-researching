#ifndef __PORT_METERS__
#define __PORT_METERS__

#include "headers.p4"

control port_meters_ingress(inout headers hdr,
                            inout standard_metadata_t standard_metadata) {
    meter(MAX_PORTS, MeterType.bytes) ingress_port_meter;
    MeterColor ingress_color = MeterColor_GREEN;

    apply {
        ingress_port_meter.execute_meter<MeterColor>((bit<32>)standard_metadata.ingress_port, ingress_color);
        if (ingress_color == MeterColor_RED) {
            mark_to_drop();
        } 
    }
}

control port_meters_egress(inout headers hdr,
                           inout standard_metadata_t standard_metadata) {

    meter(MAX_PORTS, MeterType.bytes) egress_port_meter;
    MeterColor egress_color = MeterColor_GREEN;

    apply {
        egress_port_meter.execute_meter<MeterColor>((bit<32>)standard_metadata.egress_port, egress_color);
        if (egress_color == MeterColor_RED) {
            mark_to_drop();
        } 
    }
}

#endif