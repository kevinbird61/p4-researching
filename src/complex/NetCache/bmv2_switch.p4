#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parser.p4"
#include "include/actions.p4"
// table 0
#include "include/table0.p4"

//------------------------------------------------------------------------------
// INGRESS PIPELINE
//------------------------------------------------------------------------------

control ingress(inout headers hdr,
                inout metadata_t local_metadata,
                inout standard_metadata_t standard_metadata) {

    apply {
        // L2/L3 routing
        ipv4_forwarding.apply(hdr, local_metadata, standard_metadata);
        // key-value cache
        
    }
}

//------------------------------------------------------------------------------
// EGRESS PIPELINE
//------------------------------------------------------------------------------

control egress(inout headers hdr,
               inout metadata_t local_metadata,
               inout standard_metadata_t standard_metadata) {

    apply {
        // Monitoring
    }
}

//------------------------------------------------------------------------------
// SWITCH INSTANTIATION
//------------------------------------------------------------------------------

V1Switch(
    parser_impl(),
    verify_checksum_control(),
    ingress(),
    egress(),
    compute_checksum_control(),
    deparser()
) main;