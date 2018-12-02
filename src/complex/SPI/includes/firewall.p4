#ifndef __FIREWALL__
#define __FIREWALL__

/*
    Implement the firewall function
*/

#include "headers.p4"

control firewall_func (
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action process_firewall(){
        /* 
            if match and don't want to drop, then using this state.
            To collect some useful information.
        */
        // set this packet as broadcast packet 
        // standard_metadata.mcast_grp = 1;
        // set notify packet available
        hdr.notify.setValid();
        hdr.notify.malform_srcAddr = hdr.ipv4.srcAddr;
        // using special bit in IPv4 header to indicate this packet is a "notify" packet
        hdr.ipv4.dscp = 2; // bit<6> 2
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // modify destination address 
        hdr.ipv4.srcAddr = hdr.ipv4.dstAddr;
        hdr.ipv4.dstAddr = hdr.notify.malform_srcAddr;
        // set port
        standard_metadata.egress_spec = standard_metadata.ingress_port;
        // destination MAC
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
    }

    table tb_firewall {
        key = {
            /* FIXME: using action_selector, or hashing key to replace those exact matching */
            hdr.ipv4.srcAddr: exact;
        }
        actions = {
            process_firewall;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        tb_firewall.apply();
    }
}

#endif