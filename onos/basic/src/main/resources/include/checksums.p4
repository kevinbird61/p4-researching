#ifndef __CHECKSUMS__
#define __CHECKSUMS__

#include "headers.p4"

control verify_checksum_control(inout headers_t hdr,
                                inout local_metadata_t local_metadata) {
    apply {
        // Assume checksum is always correct.
    }
}

control compute_checksum_control(inout headers_t hdr,
                                 inout local_metadata_t local_metadata) {
    apply {
        // No need to recompute.
    }
}

#endif