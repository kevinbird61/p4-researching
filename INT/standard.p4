/*
    L2,3,4 -
    standard ethernet/ip/tcp,udp headers
*/

// standard ethernet 
// transition select    - etherType
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

// standard ipv4
// diffserv             -> DSCP(6b) + ECN(2b)
// transition select    - protocol
header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;

    bit<6>  dscp;
    bit<2>  ecn;

    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

// standard tcp
header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

// standard udp
header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}