#ifndef __PARSER__
#define __PARSER__

#include "headers.p4"

// Parser
parser ingress_switch_parser(
    packet_in packet,
    out headers_t hdr,
    inout metadata_t metadata,
    in psa_ingress_parser_input_metadata_t istd,
    in resubm_metadata_t resubmit_metadata,
    in recircm_metadata_t recirculate_metadata
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
        transition select(hdr.ipv4.protocol){
            default: accept;
        }
    }
}

// Parser (egress)
parser egress_switch_parser(
    packet_in packet,
    out headers_t hdr,
    inout metadata_t metadata,
    in psa_egress_parser_input_metadata_t istd,
    in normal_metadata_t normal_metadata,
    in clone_i2e_metadata_t clone_i2e_metadata,
    in clone_e2e_metadata_t clone_e2e_metadata
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
        transition select(hdr.ipv4.protocol){
            default: accept;
        }
    }
}

// Deparser
control ingress_switch_deparser(
    packet_out packet,
    out clone_i2e_metadata_t clone_i2e_metadata,
    out resubm_metadata_t resubmit_metadata,
    out normal_metadata_t normal_metadata,
    inout headers_t hdr,
    in metadata_t metadata,
    in psa_ingress_output_metadata_t istd
){
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control egress_switch_deparser(
    packet_out packet,
    out clone_e2e_metadata_t clone_e2e_metadata,
    out recircm_metadata_t recirculate_metadata,
    inout headers_t hdr,
    in metadata_t metadata,
    in psa_egress_output_metadata_t istd,
    in psa_egress_deparser_input_metadata_t edstd
){
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

#endif