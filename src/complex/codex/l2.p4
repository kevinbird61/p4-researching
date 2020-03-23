/**
 * Define protocols in OSI layer 2
 * CONTRIBUTOR: Kevin Cyu (https://github.com/kevinbird61)
 */


/* Ethernet */
header ethernet_t {
    bit<48> dstAddr;        // Destination MAC Address
    bit<48> srcAddr;        // Source MAC Address
    bit<16> etherType;      // EtherType
}

/* IEEE 802.1Q - VLAN-tagged frame */
header vlan_t {
    bit<48> dstAddr;        // Destination MAC Address
    bit<48> srcAddr;        // Source MAC Address
    bit<16> tpid;           // Tag Protocol Identifier (TPID)
    bit<3>  pcp;            // Priority Code Point (PCP)
    bit<1>  dei;            // Drop Eligible Indicator (DEI)
    bit<12> vid;            // VLAN Identifier (VID)
    bit<16> etherType;      // EtherType
}
