#ifndef __IPV4_FORWARDING__
#define __IPV4_FORWARDING__

#include "headers.p4"
#include "actions.p4"

control ipv4_forwarding(
    inout headers hdr,
    inout metadata_t local_metadata,
    inout standard_metadata_t standard_metadata
){

    action ipv4_forwarding(bit<48> dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forwarding;
            _drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }
    }
}

#endif