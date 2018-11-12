#ifndef __CHECKSUMS__
#define __CHECKSUMS__

#include "headers.p4"

// verify checksum
control basic_tutor_verifyCk(
    inout headers_t hdr,
    inout metadata_t metadata
){
    apply {}
}

// compute checksum (need)
control basic_tutor_computeCk(
    inout headers_t hdr,
    inout metadata_t metadata
){
    apply {
        update_checksum(
            hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr
            },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16
        );
    }
}

#endif