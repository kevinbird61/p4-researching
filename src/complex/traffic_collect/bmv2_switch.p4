#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parser.p4"
#include "include/actions.p4"
// monitoring
#include "include/port_counters.p4"
#include "include/port_meters.p4"
#include "include/host_meter_table.p4"
// packet io
#include "include/packet_io.p4"
// checksums
#include "include/checksums.p4"
// table 0
#include "include/table0.p4"
// collection 
#include "include/collection.p4"

//------------------------------------------------------------------------------
// INGRESS PIPELINE
//------------------------------------------------------------------------------

control ingress(inout headers hdr,
                inout metadata_t local_metadata,
                inout standard_metadata_t standard_metadata) {

    apply {
        // Monitoring
        port_counters_ingress.apply(hdr, standard_metadata);
        port_meters_ingress.apply(hdr, standard_metadata);
        packetio_ingress.apply(hdr, standard_metadata);
        host_meter_control.apply(hdr, local_metadata, standard_metadata);

        // Flow rules
        table0_control.apply(hdr, local_metadata, standard_metadata);
    }
}

//------------------------------------------------------------------------------
// EGRESS PIPELINE
//------------------------------------------------------------------------------

control egress(inout headers hdr,
               inout metadata_t local_metadata,
               inout standard_metadata_t standard_metadata) {

    apply {
        // collection
        traffic_collection.apply(hdr, local_metadata, standard_metadata);
        // Monitoring
        port_counters_egress.apply(hdr, standard_metadata);
        port_meters_egress.apply(hdr, standard_metadata);
        packetio_egress.apply(hdr, standard_metadata);
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