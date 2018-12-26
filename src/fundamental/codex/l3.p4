/**
 * Define protocols in OSI layer 3 (including layer 2.5)
 * CONTRIBUTOR: Kevin Cyu (https://github.com/kevinbird61)
 */


/* Address Resolution Protocol (ARP) */
header arp_t {
    bit<16> htype;              // Hardware Type (HTYPE)
    bit<16> ptype;              // Protocol Type (PTYPE)
    bit<8>  hlen;               // Hardware Address Length (HLEN)
    bit<8>  plen;               // Protocol Address Length (PLAN)
    bit<16> oper;               // Operation
    bit<48> srcMacAddr;         // Source/Sender MAC Address
    bit<32> srcIpAddr;          // Source/Sender IP Address
    bit<48> dstMacAddr;         // Destination/Target MAC Address
    bit<32> dstIpAddr;          // Destination/Target IP Address
}

/* Multiprotocol Label Switching (MPLS) */
header mpls_t {
    bit<20> label;              // Label
    bit<3>  tc;                 // Traffic Class (QoS and ECN)
    bit<1>  s;                  // Bottom-of-Stack
    bit<8>  ttl;                // Time-to-Live (TTL)
}

/* Internet Control Message Protocol (ICMP) */ 
header icmp_t {
    bit<8>  type;               // ICMP Type
    bit<8>  code;               // ICMP Code
    bit<16> hdrChecksum;        // Header Checksum
    bit<16> empty;              // Unused   
    bit<16> nextHopMtu;         // Next-hop MTU
    // FIXME:
    // Need to include "IP Header"
    // And First 8 bytes of Original Datagram's Data
    // ipv4_t ipv4;
    // bit<64> originData; 
}

/* ICMP Timestamp request/response */
header icmp_ts_t {
    bit<8>  type;               // ICMP Type (req: 13 / res: 14)
    bit<8>  code;               // ICMP Code (0)
    bit<16> hdrChecksum;        // Header Checksum
    bit<16> identifier;         // Identifier
    bit<16> seq;                // Sequence Number
    bit<32> originTs;           // Originate Timestamp
    bit<32> recvTs;             // Receive Timestamp
    bit<32> tranTs;             // Transmit Timestamp
}

/* Internet Protocol version 4 (IPv4) */
header ipv4_t {
    bit<4>  version;            // Version   
    bit<4>  ihl;                // Internet Header Length (IHL)
    bit<6>  dscp;               // Differentiated Services Code Point (DSCP)
    bit<2>  ecn;                // ECN
    bit<16> totalLen;           // Total Length
    bit<16> identification;     // Identification
    bit<3>  flags;              // Flags
    bit<13> fragOffset;         // Fragment Offset
    bit<8>  ttl;                // Time-to-Live (TTL)
    bit<8>  protocol;           // Protocol
    bit<16> hdrChecksum;        // Header Checksum
    bit<32> srcAddr;            // Source Address
    bit<32> dstAddr;            // Destination Address
}

/* Internet Protocol version 6 (IPv6) */
header ipv6_t {
    bit<4>   Version;           // Version
    bit<8>   trafficClass;      // Traffic Class
    bit<20>  flowLabel;         // Flow Label
    bit<16>  payloadLen;        // Payload Length
    bit<8>   nextHeader;        // Next Header
    bit<8>   hopLimit;          // Hop Limit
    bit<128> srcAddr;           // Source Address
    bit<128> dstAddr;           // Destination Address
}
