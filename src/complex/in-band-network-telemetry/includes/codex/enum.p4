/*
    etherType/protocol number
*/

// etherType
const bit<16>   TYPE_IPV4=0x0800;
const bit<16>   TYPE_ARP=0x0806;
const bit<16>   TYPE_VLAN=0x8100; // VLAN-tagged frame
const bit<16>   TYPE_IPV6=0x86DD;
const bit<16>   TYPE_MPLS_uni=0x8847; // MPLS unicast
const bit<16>   TYPE_MPLS_mul=0x8848; // MPLS multicast

// IP protocol number 
// More reference: https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers
const bit<8>    PROTO_ICMP=1;
const bit<8>    PROTO_IPV4=4;
const bit<8>    PROTO_TCP=6;
const bit<8>    PROTO_UDP=17;
const bit<8>    PROTO_IPV6=41;

// INT 
const bit<6>    DSCP_INT=0x17;

// INT Header type - destination and hop-by-hop
const bit<8>    INT_TYPE_DST=0x1;
const bit<8>    INT_TYPE_HOP=0x2;