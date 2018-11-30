#ifndef __PARSER__
#define __PARSER__

#include "headers.p4"

// Parser
parser basic_tutor_switch_parser(
    packet_in packet,
    out headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    state start {
        transition select(standard_metadata.ingress_port){
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.packet_out);
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
        metadata.l4_srcPort = hdr.tcp.srcPort;
        metadata.l4_dstPort = hdr.tcp.dstPort;
        transition select((hdr.ipv4.dscp & INT_DSCP)){
            INT_DSCP: parse_int_shim;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        metadata.l4_srcPort = hdr.udp.srcPort;
        metadata.l4_dstPort = hdr.udp.dstPort;
        transition select((hdr.ipv4.dscp & INT_DSCP)){
            INT_DSCP: parse_int_shim;
            default: accept;
        }
    }

    /* INT parsing state */

    state parse_int_shim {
        packet.extract(hdr.int_shim);
        transition parse_int_header;
    }

    state parse_int_header {
        packet.extract(hdr.int_header);
        // parser metadata 
        metadata.parser_metadata.remaining_switch_id = HOP_CNT - hdr.int_header.remaining_hop_cnt;
        metadata.parser_metadata.remaining_hop_latency = HOP_CNT - hdr.int_header.remaining_hop_cnt;
        metadata.parser_metadata.remaining_q_occupancy = HOP_CNT - hdr.int_header.remaining_hop_cnt;

        transition select(hdr.int_shim.len - INT_HEADER_LEN_WORD){
            0: parse_int_tail; // end
            default: parse_switch_id;
        }
    }

    state parse_switch_id {
        packet.extract(hdr.int_switch_id.next); // next function
        metadata.parser_metadata.remaining_switch_id = metadata.parser_metadata.remaining_switch_id - 1;
        transition select(metadata.parser_metadata.remaining_switch_id){
            0: parse_int_hop_latency;
            default: parse_switch_id; // recursive !
        }
    }

    state parse_int_hop_latency {
        packet.extract(hdr.int_hop_latency.next); 
        metadata.parser_metadata.remaining_hop_latency = metadata.parser_metadata.remaining_hop_latency - 1;
        transition select(metadata.parser_metadata.remaining_hop_latency){
            0: parse_int_q_occupancy;
            default: parse_int_hop_latency;
        }
    }

    state parse_int_q_occupancy {
        packet.extract(hdr.int_q_occupancy.next);
        metadata.parser_metadata.remaining_q_occupancy = metadata.parser_metadata.remaining_q_occupancy - 1;
        transition select(metadata.parser_metadata.remaining_q_occupancy){
            0: parse_int_tail;
            default: parse_int_q_occupancy;
        }
    }

    state parse_int_tail {
        packet.extract(hdr.int_tail);
        transition accept;
    }
}

// Deparser
control basic_tutor_switch_deparser(
    packet_out packet,
    in headers_t hdr
){
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        // emit INT header
        packet.emit(hdr.int_shim);
        packet.emit(hdr.int_header);
        packet.emit(hdr.int_switch_id);
        packet.emit(hdr.int_port_ids);
        packet.emit(hdr.int_hop_latency);
        packet.emit(hdr.int_q_occupancy);
        packet.emit(hdr.int_ingress_ts);
        packet.emit(hdr.int_egress_ts);
        packet.emit(hdr.int_q_congestion);
        packet.emit(hdr.int_egress_port_tx_util);
        packet.emit(hdr.int_tail);
    }
}

#endif