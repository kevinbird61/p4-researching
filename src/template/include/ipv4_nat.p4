#ifndef __IPV4_NAT__
#define __IPV4_NAT__

#include "headers.p4"
#include "actions.p4"

control ipv4_nat(
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

    action nat_forward(bit<48> dstAddr, bit<32> new_ip_addr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // map the new ip addr into source addr
        hdr.ipv4.srcAddr = new_ip_addr;
    }

    action nat_reverse(bit<48> dstAddr, bit<32> ori_ip_addr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // reverse
        hdr.ipv4.dstAddr = ori_ip_addr;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forwarding;
            nat_forward;
            nat_reverse;
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