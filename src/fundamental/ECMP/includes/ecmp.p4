#ifndef __ECMP__
#define __ECMP__

#include "headers.p4"
#include "actions.p4"

control ecmp_table(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action set_ecmp_select(bit<16> ecmp_base, bit<32> ecmp_count) {
        /* TODO: hash on 5-tuple and save the hash result in meta.ecmp_select 
           so that the ecmp_nhop table can use it to make a forwarding decision accordingly */
        hash(
            metadata.ecmp_select, 
            HashAlgorithm.crc16, 
            ecmp_base, 
            {
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.protocol,
                hdr.tcp.srcPort,
                hdr.tcp.dstPort
            }, 
            ecmp_count
        );
    }

    action set_nhop(bit<48> nhop_dmac, bit<32> nhop_ipv4, bit<9> port) {
        hdr.ethernet.dstAddr = nhop_dmac;
        hdr.ipv4.dstAddr = nhop_ipv4;
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ecmp_group {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            drop;
            set_ecmp_select;
        }
        default_action = drop();
        size = 1024;
    }
    table ecmp_nhop {
        key = {
            metadata.ecmp_select: exact;
        }
        actions = {
            drop;
            set_nhop;
        }
        default_action = drop();
        size = 2;
    }

    apply {
        if (hdr.ipv4.isValid() && hdr.ipv4.ttl > 0) {
            ecmp_group.apply();
            ecmp_nhop.apply();
        }
    }
}

control ecmp_rewrite(
    inout headers_t hdr,
    inout metadata_t metadata, 
    inout standard_metadata_t standard_metadata
){
    action rewrite_mac(bit<48> smac){
        // rewrite the source 
        hdr.ethernet.srcAddr = smac;
    }

    table send_frame{
        key = {
            standard_metadata.egress_port: exact;
        }
        actions = {
            rewrite_mac;
            drop;
        }
        size = 256;
    }
    apply { 
        send_frame.apply();
    }
}

#endif