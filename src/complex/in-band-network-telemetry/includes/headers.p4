#ifndef __HEADERS__
#define __HEADERS__

#include "codex/enum.p4"
#include "codex/l2.p4"
#include "codex/l3.p4"
#include "codex/l4.p4"
#include "codex/l567.p4"

#include "int_header.p4"

// Global variable
#define CPU_PORT 255
const bit<8> HOP_CNT = 4;
const bit<8> INT_HEADER_LEN_WORD = 4;
const bit<6> INT_DSCP = 0x1;

// packet in 
@controller_header("packet_in")
header packet_in_header_t {
    bit<9>  ingress_port;
}

// packet out 
@controller_header("packet_out")
header packet_out_header_t {
    bit<9>  egress_port;
}

// header struct for packet
struct headers_t {
    packet_out_header_t     packet_out;
    packet_in_header_t      packet_in;
    ethernet_t              ethernet;
    ipv4_t                  ipv4;
    tcp_t                   tcp;
    udp_t                   udp;
    // INT headers 
    int_shim_t              int_shim;
    int_header_t            int_header;
    int_switch_id_t[HOP_CNT]    int_switch_id;
    int_port_ids_t[HOP_CNT]     int_port_ids;
    int_hop_latency_t[HOP_CNT]  int_hop_latency;
    int_q_occupancy_t[HOP_CNT]  int_q_occupancy;
    int_ingress_ts_t[HOP_CNT]   int_ingress_ts;
    int_egress_ts_t[HOP_CNT]    int_egress_ts;
    int_q_congestion_t[HOP_CNT] int_q_congestion;
    int_egress_port_tx_util_t[HOP_CNT] int_egress_port_tx_util;
    int_tail_t int_tail;
}

// int metadata type
struct int_metadata_t {
    bit<16> insert_byte_cnt;
    bit<8>  int_hdr_word_len;
    bit<32> switch_id;
    bit<8>  metadata_len;
}

struct parser_metadata_t {
    bit<8> remaining_switch_id;
    bit<8> remaining_hop_latency;
    bit<8> remaining_q_occupancy;
}

// metadata inside switch pipeline
struct metadata_t {
    bit<16> l4_srcPort;
    bit<16> l4_dstPort;
    int_metadata_t int_metadata;
    parser_metadata_t parser_metadata;
}

#endif