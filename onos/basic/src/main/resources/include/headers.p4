#ifndef __HEADERS__
#define __HEADERS__

#include "../codex/l2.p4"
#include "../codex/l3.p4"
#include "../codex/l4.p4"
#include "../codex/l567.p4"
#include "../codex/enum.p4"
#include "defines.p4"

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