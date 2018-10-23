/**
    Layer 2 protocol
*/

// standard ethernet 
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

// 802.1 Q (ethernet with VLAN)
header vlan_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> tpid;       // tag protocol identifier
    bit<3>  pcp;        // priority code point 
    bit<1>  dei;        // drop eligible indicator
    bit<12> vid;        // VLAN identifier
    // pcp + dei + vid = tci , Tag control information
    bit<16> etherType;
}