#include <core.p4>
#include <v1model.p4>

// header 
#include "../codex/l2.p4"
#include "../codex/l3.p4"

// enum
#include "../codex/enum.p4"

// define our headers
struct headers {
    ethernet_t  ethernet;
    mpls_t      mpls;
    ipv4_t      ipv4;
}

struct metadata_t {

}

/*
    Basic Parser
*/
parser Basic_parser(
    packet_in packet,
    out headers hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_MPLS_uni: parse_mpls;
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_mpls {
        packet.extract(hdr.mpls);
        transition accept;
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

/*
    Verify checksum
*/
control Basic_verifyCk(
    inout headers hdr,
    inout metadata_t metadata
){
    // TODO
    apply {

    }
}

/*
    Basic ingress
*/
control Basic_ingress(
    inout headers hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action drop() {
        mark_to_drop();
    }

    // ipv4 forward table
    action ipv4_forward(bit<48> dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action mpls_ingress(bit<9> port, bit<20> new_label){
        standard_metadata.egress_spec = port;
        // set EtherType
        hdr.ethernet.etherType = TYPE_MPLS_uni;
        // new mpls
        hdr.mpls.setValid();
        hdr.mpls.label = new_label;
    }

    // mpls forward
    action mpls_core(bit<9> port, bit<20> new_label){
        standard_metadata.egress_spec = port;
        // change new label
        hdr.mpls.setValid();
        hdr.mpls.label = new_label;
    }

    action mpls_egress(bit<48> dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.etherType = TYPE_IPV4;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // remove MPLS Layer
        hdr.mpls.setInvalid();
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            mpls_ingress;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table mpls_exact {
        key = {
            hdr.mpls.label: exact;
        }
        actions = {
            mpls_core;
            mpls_egress;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        if(hdr.mpls.isValid()){
            mpls_exact.apply();
        }
        
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }
    }
}

/*
    Basic Egress
*/
control Basic_egress(
    inout headers hdr,
    inout metadata_t meta,
    inout standard_metadata_t standard_metadata
){
    apply {

    }
}

/*
    Basic Compute Checksum
*/
control Basic_computeCk(
    inout headers hdr,
    inout metadata_t metadata
){
    apply {
        update_checksum(
            hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr
            },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16
        );
    }
}

/*
    Basic Deparser
*/
control Basic_deparser(
    packet_out packet,
    in headers hdr
){
    apply {        
        packet.emit(hdr.ethernet);
        packet.emit(hdr.mpls);
        packet.emit(hdr.ipv4);
    }

}

V1Switch(
    Basic_parser(),
    Basic_verifyCk(),
    Basic_ingress(),
    Basic_egress(),
    Basic_computeCk(),
    Basic_deparser()
) main;

// v1model
/*
V1Switch(
    parser,
    verifyChecksum
    ingress,
    egress,
    computeChecksum,
    deparser
)*/
