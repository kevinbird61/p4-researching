/**
 * Define protocols in OSI layer 4
 * CONTRIBUTOR: Kevin Cyu (https://github.com/kevinbird61)
 */


/* Transmission Control Protocol (TCP) */
header tcp_t {
    bit<16> srcPort;                // Source Port Number
    bit<16> dstPort;                // Destination Port Number
    bit<32> seq;                    // Sequence Number (SEQ)
    bit<32> ack;                    // Acknowledgment Number (ACK)
    bit<4>  dataOffset;             // Data Offset
    bit<4>  rsvd;                   // Reserved
    bit<8>  flags;                  // Flags
    bit<16> window;                 // Window Size
    bit<16> checksum;               // Checksum
    bit<16> urgentPtr;              // Urgent Pointer
}

/* User Datagram Protocol (UDP) */
header udp_t {
    bit<16> srcPort;                // Source Port Number
    bit<16> dstPort;                // Destination Port Number
    bit<16> len;                    // Length
    bit<16> checksum;               // Checksum
}

/* Virtual Extensible LAN (VXLAN) */
header vxlan_t {
    bit<8>  vxflags;                // VXLAN Flags
    bit<24> rsvd1;                  // Reserved
    bit<24> vni;                    // VXLAN NI (VNI)
    bit<8>  rsvd2;                  // Reserved
}
