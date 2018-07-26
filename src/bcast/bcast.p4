#include <core.p4>
#include <v1model.p4>

#include "../codex/l2.p4"
#include "../codex/l3.p4"
#include "../codex/enum.p4"

// for broadcast 
struct ingress_metadata_t {
    bit<32> nhop_ipv4;
}

struct metadata {
    @name("ingress_metadata")
    ingress_metadata_t ingress_metadata;
}

struct headers {
    @name("ethernet")
    ethernet_t ethernet;
    @name("ipv4")
    ipv4_t ipv4;
}

// Parser 
parser Bcast_parser(
    packet_in packet,
    out headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    state start{
        transition parse_ethernet;
    }

    state parse_ethernet{
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4{
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

// verify checksum
control Bcast_verifyChecksum(
    inout headers hdr, inout metadata meta
){
    apply { }
}

// Ingress 
control Bcast_ingress(
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    action _drop(){
        mark_to_drop();
    }

    action set_nhop(bit<32> nhop_ipv4, bit<9> port){
        meta.ingress_metadata.nhop_ipv4 = nhop_ipv4;
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action broadcast(){
        standard_metadata.mcast_grp = 1;
        meta.ingress_metadata.nhop_ipv4 = hdr.ipv4.dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action set_dmac(bit<48> dmac){
        hdr.ethernet.dstAddr = dmac;
    }

    table ipv4_lpm {
        actions = {
            _drop;
            set_nhop;
            broadcast;
            NoAction;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 1024;
        default_action = NoAction();
    }

    table forward {
        actions = {
            set_dmac;
            _drop;
            NoAction;
        }
        key = {
            meta.ingress_metadata.nhop_ipv4: exact;
        }
        size = 512;
        default_action = NoAction();
    }

    apply {
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
            forward.apply();
        }
    }
}

// egress 
control Bcast_egress(
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    action rewrite_mac(bit<48> smac){
        hdr.ethernet.srcAddr = smac;
    }

    action _drop(){
        mark_to_drop();
    }

    table send_frame{
        actions = {
            rewrite_mac;
            _drop;
            NoAction;
        }
        key = {
            standard_metadata.egress_port: exact;
        }
        size = 256;
        default_action = NoAction();
    }

    apply {
        if(hdr.ipv4.isValid()){
            send_frame.apply();
        }
    }
}

// compute checksum
control Bcast_computeChecksum(
    inout headers hdr, inout metadata meta
){
    apply {
        update_checksum(
            hdr.ipv4.isValid(),
            { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv,
            hdr.ipv4.totalLen, hdr.ipv4.identification,
            hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl,
            hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

// deparser 
control Bcast_deparser(
    packet_out packet,
    in headers hdr
){
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

V1Switch(
    Bcast_parser(),
    Bcast_verifyChecksum(),
    Bcast_ingress(),
    Bcast_egress(),
    Bcast_computeChecksum(),
    Bcast_deparser()
) main;
