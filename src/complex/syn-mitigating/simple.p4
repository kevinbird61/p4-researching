#include <core.p4>
#include <v1model.p4>

// header 
#include "../codex/l2.p4"
#include "../codex/l3.p4"
#include "../codex/l4.p4"

// enum
#include "../codex/enum.p4"

const bit<32> MAX_COUNTER_SIZE = 1<<16;

// define our headers
struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
    tcp_t   tcp;
}

struct syn_ack_digest{
    bit<32> IP;
}

struct check_digest{
    bit<32> dst_IP;
    bit<32> index;
}

struct merge_digest{
    bit<32> index;
}

struct debug_digest{
    bit<32> apply_index;
    bit<32> syn_ack;
    bit<32> ack;
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
            PROTO_TCP: parse_tcp;
            default: accept;
        }
    }
    
    state parse_tcp {
        packet.extract(hdr.tcp);
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
    // counter(MAX_COUNTER_SIZE, CounterType.packets_and_bytes) ingressTunnelCounter;

    // using register to counting
    register<bit<32>>(2048) synackCount;
    register<bit<32>>(2048) ackCount;
    // 0:total/ 1~512:classD/ 513~1024:classABC

    bit<32> apply_index=0;

    action new_synack(){
        digest<syn_ack_digest>((bit<32>) 1024,
        {
            hdr.ipv4.dstAddr
        });
    }

    action checking(){
        digest<check_digest>((bit<32>) 1024,
        {
            hdr.ipv4.dstAddr,
            apply_index
        });
    }

    action merge(){
        digest<merge_digest>((bit<32>) 1024,
        {
            apply_index
        });
    }

    // action debug(bit<32> syn_ack, bit<32> ack){
    //     digest<debug_digest>((bit<32>) 1024,
    //     {
    //         apply_index,
    //         syn_ack,
    //         ack
    //     });
    // }

    action synack_counting(bit<32> index){
        bit<32> previous = 32w0;
        bit<32> ack_count = 32w0;
        apply_index = index;
        synackCount.read(previous, index);
        synackCount.write(index, previous+1);
        synackCount.read(previous, 0);
        synackCount.write(0, previous+1);
    }

    action ack_counting(bit<32> index){
        bit<32> previous = 32w0;
        ackCount.read(previous, index);
        ackCount.write(index, previous+1);
        ackCount.read(previous, 0);
        ackCount.write(0, previous+1);
    }
    

    action drop() {
        mark_to_drop();
    }

    // ipv4 forward table
    action host_forward(bit<48> dstAddr, bit<9> port){
        standard_metadata.egress_spec = port;
        // hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // counter - using port as id
        // ingressTunnelCounter.count((bit<32>)port);
    }

    action l3_forward(bit<9> port){
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        // counter - using port as id
        // ingressTunnelCounter.count((bit<32>)port);
    }
  
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            host_forward;
            l3_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table syn_drop {
        key = {
            hdr.ipv4.dstAddr: lpm;
            standard_metadata.ingress_port:exact;
        }
        actions = {
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table synack_entry {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            synack_counting;
            checking;
            //debug;
            merge;
            new_synack;
        }
        size = 1024;
        default_action = new_synack();
    }
    
    table ack_entry {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ack_counting;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        if(hdr.ipv4.isValid()){
            // ingressTunnelCounter.count(2);
            if (syn_drop.apply().hit){
                return;
            }
            if(hdr.ipv4.protocol == PROTO_TCP){
                bit<32> synack_num = 0;
                bit<32> ack_num = 0;
                if((hdr.tcp.flags & 8w0b00010010) == 8w0b00010010){
                    synack_entry.apply();

                    //detect syn flooding
                    if(apply_index >= 1500){
                        // class ABC
                        synackCount.read(synack_num, apply_index);
                        ackCount.read(ack_num, apply_index);
                        //debug(synack_num,ack_num);
                        if(synack_num>=29){
                            if((synack_num-ack_num)>=3) {checking();}
                            synackCount.write(apply_index,0); // (index, value)
                            ackCount.write(apply_index,0);
                        }
                    }else{
                        // detect synflood classD
                        synackCount.read(synack_num, apply_index); // (value,index)
                        ackCount.read(ack_num, apply_index); 
                        if(synack_num>3 && ack_num==0){checking();}
                    }
                }else if((hdr.tcp.flags & 8w0b00011001) == 8w0b00011001){
                    ack_entry.apply();
                }

                synackCount.read(synack_num, 0);
                if(synack_num>=40){
                    merge();
                    synackCount.write(0,0);
                    ackCount.write(0,0);
                }
            }
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
        packet.emit(hdr.ipv4);
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
