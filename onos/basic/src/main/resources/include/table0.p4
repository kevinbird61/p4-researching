// For one table control 
#ifndef __TABLE0__
#define __TABLE0__

#include "headers.p4"
#include "defines.p4"

control table0_control(inout headers_t hdr,
                       inout local_metadata_t local_metadata,
                       inout standard_metadata_t standard_metadata) {

    direct_counter(CounterType.packets_and_bytes) table0_counter;

    action set_next_hop_id(next_hop_id_t next_hop_id) {
        local_metadata.next_hop_id = next_hop_id;
    }

    action send_to_cpu() {
        standard_metadata.egress_spec = CPU_PORT;
    }

    action set_egress_port(port_t port) {
        standard_metadata.egress_spec = port;
    }

    table table0 {
        key = {
            standard_metadata.ingress_port : ternary;
            hdr.ethernet.srcAddr          : ternary;
            hdr.ethernet.dstAddr          : ternary;
            hdr.ethernet.etherType        : ternary;
            hdr.ipv4.srcAddr              : ternary;
            hdr.ipv4.dstAddr              : ternary;
            hdr.ipv4.protocol              : ternary;
            local_metadata.l4_src_port     : ternary;
            local_metadata.l4_dst_port     : ternary;
        }
        actions = {
            set_egress_port;
            send_to_cpu;
            set_next_hop_id;
            _drop;
        }
        const default_action = _drop();
        counters = table0_counter;
    }

    apply {
        table0.apply();
     }
}

#endif