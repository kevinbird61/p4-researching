#include <core.p4>
#include <v1model.p4>

// header 
#include "../codex/l2.p4"
#include "../codex/l3.p4"

// enum 
#include "../codex/enum.p4"

// define meter color value
typedef bit<8> MeterColor;
const MeterColor MeterColor_GREEN = 8w1;
const MeterColor MeterColor_YELLOW = 8w2;
const MeterColor MeterColor_RED = 8w3;

// define our headers
struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
}

struct metadata_t {
    // empty
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
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
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
    apply {
        // do nothing
    }
}

/*
    Meter 
*/
control Ingress_port_meters(
    inout headers hdr, 
    inout standard_metadata_t standard_metadata
){
    // MAX_PORT size = 511
    // meter(511, MeterType.bytes) ingress_port_meter;
    meter(511, MeterType.packets) ingress_port_meter;
    MeterColor ingress_color = MeterColor_GREEN;
    
    apply {
        ingress_port_meter.execute_meter<MeterColor>((bit<32>) standard_metadata.ingress_port, ingress_color);

        // For experiment, if detecting color is yellow, then we drop 
        if(ingress_color == MeterColor_YELLOW){
            // if execute drop operation, then this packet will directly drop, 
            // won't execute the operation/action behind.
            mark_to_drop();
        }
    }
}

control Egress_port_meters(
    inout headers hdr, 
    inout standard_metadata_t standard_metadata
){
    // MAX_PORT size = 511
    // meter(511, MeterType.bytes) egress_port_meter;
    meter(511, MeterType.packets) egress_port_meter;
    MeterColor egress_color = MeterColor_GREEN;
    
    apply {
        egress_port_meter.execute_meter<MeterColor>((bit<32>) standard_metadata.egress_port, egress_color);

        // For experiment, if detecting color is yellow, then we drop 
        if(egress_color == MeterColor_YELLOW){
            // if execute drop operation, then this packet will directly drop, 
            // won't execute the operation/action behind.
            mark_to_drop();
        }
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

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        // apply meter first 
        Ingress_port_meters.apply(hdr, standard_metadata);

        // if pass meter checking, go ipv4 operations
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
        // apply meter 
        Egress_port_meters.apply(hdr, standard_metadata);
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
        // do nothing
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