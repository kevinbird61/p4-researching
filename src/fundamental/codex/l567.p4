/*
    Layer 5,6,7 protocol
*/

// SIP Header Format
header sip_t {
    bit<4>  version;
    bit<28> flowLabel;
    bit<16> payloadLen;
    bit<8>  payloadType;
    bit<8>  hopLimit;
    bit<32> srcAddr;
    bit<32> dstAddr;
}
