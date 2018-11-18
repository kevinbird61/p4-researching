#ifndef __HEADERS__
#define __HEADERS__

#include "codex/enum.p4"
#include "codex/l2.p4"
#include "codex/l3.p4"
#include "codex/l4.p4"
#include "codex/l567.p4"

#define CPU_PORT 255

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
}

// metadata inside switch pipeline
struct metadata_t {
    bit<16> l4_srcPort;
    bit<16> l4_dstPort;
    bit<32> hash_key; // hash by 5-tuple, size = 1024 ( 2^10, set 10 bits size for hashkey )
}

#endif