#ifndef __IPV4V6_TRANSLATION__
#define __IPV4V6_TRANSLATION__

#include "headers.p4"
#include "actions.p4"

/* work-in-process */

control ipv4v6_translation(
    inout headers hdr,
    inout metadata_t local_metadata,
    inout standard_metadata_t standard_metadata
){

    action ipv4_forwarding(bit<48> dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // set if ipv6 is valid
        hdr.ipv6.setInvalid();
    }

    // ipv6 forward table 
    action ipv6_forward(bit<48> dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 1;
        hdr.ipv4.setInvalid();
    }

    // ipv6 -> ipv4 
    action ipv6_translate(bit<48> dstAddr, bit<32> ipv4srcAddr, bit<32> ipv4dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        // Switch to correspond ipv4 information\
        hdr.ethernet.etherType = TYPE_IPV4;
        hdr.ipv4.setValid();
        // origin part
        hdr.ipv4.version = hdr.ipv6.version;
        hdr.ipv4.protocol = hdr.ipv6.nextHeader;
        hdr.ipv4.ttl = hdr.ipv6.hopLimit;
        hdr.ipv4.totalLen = hdr.ipv6.payloadLen;
        // src,dst 
        // Notice: only specify directly in demo, can't use in real env
        hdr.ipv4.srcAddr = ipv4srcAddr;
        hdr.ipv4.dstAddr = ipv4dstAddr;
        // eliminate ipv6
        hdr.ipv6.setInvalid();
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

    table ipv6_lpm {
        key = {
            hdr.ipv6.dstAddr: lpm;
        }
        actions = {
            ipv6_forward;
            ipv6_translate;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }
        else if(hdr.ipv6.isValid()){
            ipv6_lpm.apply();
        }
    }
}

#endif