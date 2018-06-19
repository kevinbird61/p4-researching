/**
    Layer 2 protocol
*/

// ethernet 
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}