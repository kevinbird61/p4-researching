#include <core.p4>
#include <v1model.p4>

// header 
#include "../codex/l2.p4"
#include "../codex/l3.p4"

// enum
#include "../codex/enum.p4"

// define our headers
struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
}

struct metadata_t {

}

/*
    Basic Parser
*/
parser BasicParser(
    packet_in packet,
    out headers hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }   
}

/*
    Verify checksum
*/
control Basic_verifyCk(
    inout headers hdr,
    inout metadata_t metadata
){
    
}


// v1model
/*
V1Switch(
    parser,
    verifyChecksum
    ingress,
    egress,
    computeChecksum,
    deparser
)*/