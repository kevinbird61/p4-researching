#ifndef __HEADERS__
#define __HEADERS__

#include "../codex/enum.p4"
#include "../codex/l2.p4"
#include "../codex/l3.p4"
#include "../codex/l4.p4"
#include "../codex/l567.p4"

#define MAX_PORTS 511

typedef bit<9>  port_t;
typedef bit<16> next_hop_id_t;

const port_t CPU_PORT = 255;

typedef bit<8> MeterColor;
const MeterColor MeterColor_GREEN = 8w0;
const MeterColor MeterColor_YELLOW = 8w1;
const MeterColor MeterColor_RED = 8w2;

// header struct for packet
struct headers {
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
    ethernet_t ethernet;
    ipv4_t ipv4;
    tcp_t tcp;
    udp_t udp;
}

struct metadata_t {
    bit<16>       l4_src_port;
    bit<16>       l4_dst_port;
    next_hop_id_t next_hop_id;
}

// packet-in (send-to-controller)
@controller_header("packet_in")
header packet_in_header_t {
    bit<9>  ingress_port;
    bit<7>  _padding;
}

// packet-out (send-from-controller)
@controller_header("packet_out")
header packet_out_header_t {
    bit<9>  egress_port;
    bit<7>  _padding;
}

#endif