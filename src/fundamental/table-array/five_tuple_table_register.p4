#include <core.p4>
#include <v1model.p4>

#include "../codex/l2.p4"
#include "../codex/l3.p4"
#include "../codex/l4.p4"
#include "../codex/enum.p4"

struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
    tcp_t       tcp;
    udp_t       udp;
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
        transition select(hdr.ipv4.protocol){
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
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
    apply {

    }
}

/*
    5-tuple 
*/
control Five_tuple_calc(
    inout headers hdr,
    inout metadata_t metadata
){
    register<bit<32>>(1024) five_tuple_table;

    // Maintain 5-tuple table entry here.
    // using register to maintain table
    /*
        The prime number is used because when one value is multiplied by a prime number 
        it tends to have a higher probability of remaining unique when other similar 
        operations are accumulated on top of it. The specific value 59 may have been 
        choosen arbitrarily or it may be intentional. It is hard to tell. It is possible 
        that 59 tended to generate a better distribution of values based on the most likely inputs.
    */
    apply {
        if(hdr.ipv4.isValid() && hdr.tcp.isValid()){
            // calc 5-tuple from:
            // - ipv4 src
            // - ipv4 dst
            // - src port
            // - dst port
            // - protocol
            /* bit<32> index = (bit<32>)(
                (hdr.ipv4.srcAddr * 59) ^ 
                (hdr.ipv4.dstAddr) ^
                ((bit<32>)hdr.tcp.srcPort << 16) ^
                ((bit<32>)hdr.tcp.dstPort) ^ 
                ((bit<32>)hdr.ipv4.protocol));
                */
            // Notice: Because need to let the index value set in range 0~1023,
            // so shift them brutally
            bit<32> index = (bit<32>)(
                (hdr.ipv4.srcAddr >> 25) ^ 
                (hdr.ipv4.dstAddr >> 25) ^
                ((bit<32>)hdr.tcp.srcPort >> 8) ^
                ((bit<32>)hdr.tcp.dstPort >> 8) ^ 
                ((bit<32>)hdr.ipv4.protocol));
            // get the previous value
            bit<32> previous = 32w0; 
            five_tuple_table.read(previous, index);
            // +1 
            five_tuple_table.write(index, previous+1);
        }
        else if(hdr.ipv4.isValid() && hdr.udp.isValid()){
            // calc 5-tuple from:
            // - ipv4 src
            // - ipv4 dst
            // - src port
            // - dst port
            // - protocol
            /* bit<32> index = (bit<32>)(
                (hdr.ipv4.srcAddr * 59) ^ 
                (hdr.ipv4.dstAddr) ^
                ((bit<32>)hdr.udp.srcPort << 16) ^
                ((bit<32>)hdr.udp.dstPort) ^ 
                ((bit<32>)hdr.ipv4.protocol));*/
            // Notice: Because need to let the index value set in range 0~1023,
            // so shift them brutally
            bit<32> index = (bit<32>)(
                (hdr.ipv4.srcAddr >> 25) ^ 
                (hdr.ipv4.dstAddr >> 25) ^
                ((bit<32>)hdr.udp.srcPort >> 8) ^
                ((bit<32>)hdr.udp.dstPort >> 8) ^ 
                ((bit<32>)hdr.ipv4.protocol));
            // get the previous value
            bit<32> previous = 32w0; 
            five_tuple_table.read(previous, index);
            // +1 
            five_tuple_table.write(index, previous+1);
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
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
            // then apply 5-tuple 
            Five_tuple_calc.apply(hdr, metadata);
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
        // Now empty
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