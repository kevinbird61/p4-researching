/*
    Basic P4 switch program for tutor. (with simple functional support)
*/
#include <core.p4>
#include <v1model.p4>

#include "includes/headers.p4"
#include "includes/actions.p4"
#include "includes/checksums.p4"
#include "includes/parser.p4"

// application
#include "includes/ipv4_forward.p4"
#include "includes/int_source.p4"
#include "includes/int_transit.p4"
#include "includes/int_sink.p4"
#include "includes/int_common.p4"

//------------------------------------------------------------------------------
// INGRESS PIPELINE
//------------------------------------------------------------------------------
control basic_tutorial_ingress(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    apply {
        /* Pipelines in Ingress */

        // forwarding
        ipv4_forwarding.apply(hdr, metadata, standard_metadata);

        // INT source/transit/sink (using Match/Action rules to specify which type on that switch)
        int_source.apply(hdr, metadata, standard_metadata);
        int_transit.apply(hdr, metadata, standard_metadata);
        int_sink.apply(hdr, metadata, standard_metadata);


    }
}

//------------------------------------------------------------------------------
// EGRESS PIPELINE
//------------------------------------------------------------------------------
control basic_tutorial_egress(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    apply {
        /* Pipelines in Egress */

        // INT 
        int_clone.apply(hdr, metadata, standard_metadata);
    }
}

//------------------------------------------------------------------------------
// SWITCH ARCHITECTURE
//------------------------------------------------------------------------------
V1Switch(
    basic_tutor_switch_parser(),
    basic_tutor_verifyCk(),
    basic_tutorial_ingress(),
    basic_tutorial_egress(),
    basic_tutor_computeCk(),
    basic_tutor_switch_deparser()
) main;