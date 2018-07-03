#include <core.p4>
#include <v1model.p4>

#include "../codex/enum.p4"
#include "../codex/l2.p4"
#include "../codex/l3.p4"

// advance tunnel
const bit<16> TYPE_TUNNEL = 0x1212;
const bit<32> MAX_TUNNEL_ID = 1 << 16;

typedef bit<9> egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header tunnel_t {
    bit<16> proto_id;
    bit<16> dst_id;
}

struct metadata {

}

struct headers {
    ethernet_t  ethernet;
    tunnel_t    tunnel;
    ipv4_t      ipv4;
}

/*
    Tunnel Parser
*/
parser Tunnel_parser(
    packet_in packet,
    out headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select (hdr.ethernet.etherType){
            TYPE_TUNNEL: parse_Tunnel;
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_Tunnel {
        packet.extract(hdr.tunnel);
        transition select(hdr.tunnel.proto_id){
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
    Tunnel verifyChecksum
*/
control Tunnel_verifyCk(
    inout headers hdr,
    inout metadata meta 
){
    apply {

    }
}

/*
    Tunnel ingress
*/
control Tunnel_ingress(
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    // only available in Ingress!
    counter(MAX_TUNNEL_ID, CounterType.packets_and_bytes) ingressTunnelCounter;
    counter(MAX_TUNNEL_ID, CounterType.packets_and_bytes) egressTunnelCounter;

    action drop(){
        mark_to_drop();
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action tunnel_ingress(bit<16> dst_id){
        hdr.tunnel.setValid();
        hdr.tunnel.dst_id = dst_id;
        hdr.tunnel.proto_id = hdr.ethernet.etherType;
        hdr.ethernet.etherType = TYPE_TUNNEL;
        ingressTunnelCounter.count((bit<32>) hdr.tunnel.dst_id);
    }

    action tunnel_forward(egressSpec_t port){
        standard_metadata.egress_spec = port;
    }

    action tunnel_egress(macAddr_t dstAddr, egressSpec_t port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ethernet.etherType = hdr.tunnel.proto_id;
        hdr.tunnel.setInvalid();
        egressTunnelCounter.count((bit<32>) hdr.tunnel.dst_id); 
    }

    // table 
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            tunnel_ingress;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table tunnel_exact {
        key = {
            hdr.tunnel.dst_id: exact;
        }
        actions = {
            tunnel_forward;
            tunnel_egress;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    apply {
        if(hdr.ipv4.isValid() && !hdr.tunnel.isValid()){
            // Process only non-tunneled IPV4
            ipv4_lpm.apply();
        }
        if(hdr.tunnel.isValid()){
            // Process all
            tunnel_exact.apply();
        }
    }
}

/*
    Tunnel Egress
*/
control Tunnel_egress(
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    apply {

    }
}

/*
    Tunnel Compute Checksum
*/
control Tunnel_computeCk(
    inout headers hdr,
    inout metadata meta
){
    apply {
        update_checksum(
            hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
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
    Tunnel Deparser
*/
control Tunnel_deparser(
    packet_out packet,
    in headers hdr
){
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.tunnel);
        packet.emit(hdr.ipv4);
    }
}

/**
    V1Switch
*/
V1Switch(
    Tunnel_parser(),
    Tunnel_verifyCk(),
    Tunnel_ingress(),
    Tunnel_egress(),
    Tunnel_computeCk(),
    Tunnel_deparser()
) main;
