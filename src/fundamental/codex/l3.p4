/**
    Layer 3 protocol (including Layer 2.5 )
*/

// ARP IP protocol 
header arp_t {
    bit<8>  htype;      // HW type
    bit<8>  ptype;      // Protocol type
    bit<4>  hlen;       // HW addr len
    bit<4>  oper;       // Proto addr len
    bit<48> srcMacAddr; // source mac addr
    bit<32> srcIPAddr;  // source IP addr
    bit<48> dstMacAddr; // destination mac addr
    bit<32> dstIPAddr;  // destination IP addr
}

// ICMP - timestamp request/response
header icmp_ts_t {
    bit<8> type;
    bit<8> code;
    bit<16> hdrChecksum;
    bit<16> identifier;
    bit<16> seqNum;
    bit<32> originTs;       // originate timestamp
    bit<32> recvTs;         // receive timestamp
    bit<32> tranTs;         // transmit timestamp
}

// ICMP 
header icmp_t {
    bit<8> type;
    bit<8> code;
    bit<16> hdrChecksum;
    bit<16> empty;
    bit<16> nextHopMtu;
    // FIXME:
    // Need to include "IP Header"
    // And First 8 bytes of Original Datagram's Data
    // ipv4_t ipv4;
    // bit<64> originData; 
}

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
