/*
    Basic P4 switch program for tutor. (with simple functional support)
*/
#include <core.p4>
#include <psa.p4>

#include "includes/headers.p4"
#include "includes/parser.p4"

// application
// #include "includes/ipv4_forward.p4"

//------------------------------------------------------------------------------
// INGRESS PIPELINE
//------------------------------------------------------------------------------
control psa_tutorial_ingress(
    inout headers_t hdr,
    inout metadata_t metadata,
    in    psa_ingress_input_metadata_t  istd,
    inout psa_ingress_output_metadata_t ostd
){
    apply {
        /* Pipelines in ingress */
    }
}

//------------------------------------------------------------------------------
// EGRESS PIPELINE
//------------------------------------------------------------------------------
control psa_tutorial_egress(
    inout headers_t hdr,
    inout metadata_t metadata,
    in    psa_egress_input_metadata_t  istd,
    inout psa_egress_output_metadata_t ostd
){
    apply {
        /* Pipelines in Egress */
    }
}

//------------------------------------------------------------------------------
// SWITCH ARCHITECTURE
//------------------------------------------------------------------------------
IngressPipeline(
    ingress_switch_parser(),
    psa_tutorial_ingress(),
    ingress_switch_deparser()) ip;

EgressPipeline(
    egress_switch_parser(),
    psa_tutorial_egress(),
    egress_switch_deparser()) ep;

PSA_Switch(
    ip,
    PacketReplicationEngine(),
    ep,
    BufferingQueueingEngine()
) main;