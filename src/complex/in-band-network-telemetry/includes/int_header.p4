#ifndef __INT_HEADERS__
#define __INT_HEADERS__

// INT shim header 
header int_shim_t {
    bit<8> int_type;
    bit<8> rsvd1;
    bit<8> len;
    bit<8> rsvd2;
}

// INT tail header 
header int_tail_t {
    bit<8> next_proto;
    bit<16> dest_port;
    bit<8> dscp;
}

// INT headers 
header int_header_t {
    bit<4> ver;
    bit<2> rep;
    bit<1> c;
    bit<1> e;
    bit<1> m;
    bit<7> rsvd1;
    bit<3> rsvd2;
    bit<5> ins_cnt;
    bit<8> remaining_hop_cnt;
    bit<4> instr_mask_0003;
    bit<4> instr_mask_0407;
    bit<4> instr_mask_0811;
    bit<4> instr_mask_1215;
    bit<16> rsvd3;
}

header int_switch_id_t {
    bit<32> switch_id;
}

header int_port_ids_t {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}

header int_hop_latency_t {
    bit<32> hop_latency;
}

header int_q_occupancy_t {
    bit<8> q_id;
    bit<24> q_occupancy;
}

header int_ingress_ts_t{
    bit<32> ingress_ts;
}

header int_egress_ts_t{
    bit<32> egress_ts;
}

header int_q_congestion_t {
    bit<8> q_id;
    bit<24> q_congestion;
}

header int_egress_port_tx_util_t {
    bit<32> egress_port_tx_util;
}

#endif