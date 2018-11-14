#ifndef __WCMP__
#define __WCMP__ 

#include "headers.p4"
#include "actions.p4"

control wcmp_control(inout headers_t hdr,
                     inout metadata_t metadata,
                     inout standard_metadata_t standard_metadata) {

    direct_counter(CounterType.packets_and_bytes) wcmp_table_counter;
    action_selector(HashAlgorithm.crc16, 32w64, 32w16) wcmp_selector;

    action set_egress_port(bit<9> port) {
        standard_metadata.egress_spec = port;
    }

    table wcmp_table {
        support_timeout = false;
        key = {
            // metadata.next_hop_id : exact;
            hdr.ipv4.srcAddr     : selector;
            hdr.ipv4.dstAddr     : selector;
            hdr.ipv4.protocol    : selector;
            metadata.l4_srcPort : selector;
            metadata.l4_dstPort : selector;
        }
        actions = {
            set_egress_port;
            NoAction;
        }
        implementation = wcmp_selector;
        counters = wcmp_table_counter;
    }

    apply {
        wcmp_table.apply();
    }
}

#endif