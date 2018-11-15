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
    ethernet_t              ethernet;
    ipv4_t                  ipv4;
}

// metadata inside switch pipeline
struct metadata_t {

}

// resubmit metadata 
struct resubm_metadata_t {

}

// recirculate metadata
struct recircm_metadata_t {
    
}

// CI2EM 
struct clone_i2e_metadata_t {

}

// CE2EM
struct clone_e2e_metadata_t {

}

// NM (normal metadata)
struct normal_metadata_t {

}

#endif