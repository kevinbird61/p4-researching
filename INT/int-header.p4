/**
    Data structure definition of INT
*/

// INT shim header for TCP/UDP 
/*
    rsvd = reserved 
*/
header int_tcpudp_shim_t{
    bit<8>  int_type;
    bit<8>  rsvd1;
    bit<8>  len;
    bit<6>  dscp;
    bit<2>  rsvd2;
}

// INT Header 
/* 
    16 instruction bits are defined in four 4b fields to allow concurrent
    lookups of the bits without listing 2^16 combinations.

    rsvd = reserved 
*/
header int_header_t {
    bit<4>  ver;
    bit<2>  rep;
    bit<1>  c;
    bit<1>  e;
    bit<1>  m;
    bit<7>  rsvd1;
    bit<3>  rsvd2;
    bit<5>  hop_metadata_len;
    bit<8>  remaining_hop_cnt;
    bit<4>  instruction_mask_0003;
    bit<4>  instruction_mask_0407;
    bit<4>  instruction_mask_0811;
    bit<4>  instruction_mask_1215;
    bit<16> rsvd3;
}

// INT meta-value headers
/* 
    different header for each value type,
    which will specify by instruction bitmap
    * bit 0 (MSB): Switch ID
    * bit 1: Level 1 Ingress Port ID (16 bits) + Egress Port ID (16 bits)
    * bit 2: Hop latency
    * bit 3: Queue ID (8 bits) + Queue Occupancy (24 bits)
    * bit 4: Ingress timestamp
    * bit 5: Egress timestamp
    * bit 6: Level 2 Ingress Port ID + Egress Port ID (4 bytes each)
    * bit 7: Egress Port TX utilization
    * bit 15: Checksum Complement 

    And the rest of bits are reserved.
*/
header int_switch_id_t {
    bit<32> switch_id;
}

header int_level1_port_ids_t {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}

header int_q_occupancy_t {
    bit<8>  q_id;
    bit<24> q_occupancy;
}

header int_ingress_tstamp_t {
    bit<32> ingress_tstamp;
}

header int_egress_tstamp_t {
    bit<32> egress_tstamp;
}

header int_level2_port_ids_t {
    bit<32> ingress_port_id;
    bit<32> egress_port_id;
}

header int_egress_port_tx_util_t {
    bit<32> egress_port_tx_util;
}