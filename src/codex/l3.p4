/**
    Layer 3 protocol (including Layer 2.5 )
*/

// MPLS
header mpls_t {
    bit<20> label;
    bit<3>  tc; // traffic class (QoS and ECN)
    bit<1>  s;  // bottom-of-stack
    bit<8>  ttl;// time-of-live
}

// standard ipv4
// transition select    - protocol
header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
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

// standard ipv6
// transition select    - nextHeader
header ipv6_t {
    bit<4>      version;
    bit<8>      trafficClass;
    bit<20>     flowlabel;
    bit<16>     payloadLen;
    bit<8>      nextHeader;
    bit<8>      hopLimit;
    bit<128>    srcAddr;
    bit<128>    dstAddr;
}