#ifndef __INT_SINK__
#define __INT_SINK__

#include "headers.p4"
#include "int_common.p4"

control int_sink(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    table int_sink_table {
        key = { 
            standard_metadata.ingress_port: exact;
        }
        actions = {
            /* TODO */
        }
        size = 1024;
    }

    apply {
        // call 
        int_sink_table.apply();
    }
}

#endif