#ifndef __WCMP__
#define __WCMP__ 

#include "headers.p4"
#include "defines.p4"
#include "actions.p4"

control wcmp_control(inout headers_t hdr,
                     inout local_metadata_t local_metadata,
                     inout standard_metadata_t standard_metadata) {

    direct_counter(CounterType.packets_and_bytes) wcmp_table_counter;
    action_selector(HashAlgorithm.crc16, 32w64, 32w16) wcmp_selector;

    action set_egress_port(port_t port) {
        standard_metadata.egress_spec = port;
    }

    table wcmp_table {
        support_timeout = false;
        key = {
            local_metadata.next_hop_id : exact;
            hdr.ipv4.srcAddr          : selector;
            hdr.ipv4.dstAddr          : selector;
            hdr.ipv4.protocol          : selector;
            local_metadata.l4_src_port : selector;
            local_metadata.l4_dst_port : selector;
        }
        actions = {
            set_egress_port;
        }
        implementation = wcmp_selector;
        counters = wcmp_table_counter;
        // default action support 
        // const default_action = _drop();
    }

    apply {
        if (local_metadata.next_hop_id != 0) {
            wcmp_table.apply();
        }
    }
}

#endif
