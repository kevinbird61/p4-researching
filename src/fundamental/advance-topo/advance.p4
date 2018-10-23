#include <core.p4>
#include <v1model.p4>

// header 
#include "../codex/l2.p4"
#include "../codex/l3.p4"
#include "../codex/l4.p4"

// enum
#include "../codex/enum.p4"

const bit<32> MAX_COUNTER_SIZE = 1<<16;
const bit<32> PKT_INDEX=0;
const bit<32> TCP_INDEX=1;
const bit<32> UDP_INDEX=1;

// define our headers
struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
    udp_t       udp;
    tcp_t       tcp;
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
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            PROTO_TCP:  parse_tcp;
            PROTO_UDP:  parse_udp;
            default: accept;
        }
    }   

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
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
    // using counter as monitoring
    counter(MAX_COUNTER_SIZE, CounterType.packets_and_bytes) PktCounter; // count all packets
    counter(MAX_COUNTER_SIZE, CounterType.packets_and_bytes) TCPcounter; // count only tcp 
    counter(MAX_COUNTER_SIZE, CounterType.packets_and_bytes) UDPcounter; // count only udp
    
    action drop() {
        mark_to_drop();
    }

    // ipv4 forward table
    action ipv4_forward(bit<48> dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // count , using PKT_INDEX as index
        PktCounter.count(PKT_INDEX);
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
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
            if(hdr.udp.isValid()){
                // using 0 as index
                UDPcounter.count(UDP_INDEX);
            }
            if(hdr.tcp.isValid()){
                // using 0 as index
                TCPcounter.count(TCP_INDEX);
            }
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
    Basic Deparser
*/
control Basic_deparser(
    packet_out packet,
    in headers hdr
){
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
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
