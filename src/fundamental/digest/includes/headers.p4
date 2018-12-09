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
    bit<16>  ingress_port;
}

// packet out 
@controller_header("packet_out")
header packet_out_header_t {
    bit<16>  egress_port;
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

// digest
struct mac_learn_digest_t {
    bit<48> srcAddr;
    bit<48> dstAddr;
    bit<16> etherType;
    bit<16>  ingress_port;
}

// metadata inside switch pipeline
struct metadata_t {

}

#endif