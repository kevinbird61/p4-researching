#ifndef __INT_SOURCE__
#define __INT_SOURCE__

#include "headers.p4"
#include "int_common.p4"

control int_source(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    // source, receive the INT instruction
    action int_source_dscp(
        bit<5> ins_cnt, 
        bit<4> ins_mask0003,
        bit<4> ins_mask0407,
        bit<16> ecmp_base,
        bit<32> ecmp_count
    ){
        // initial INT Header
        hdr.int_shim.setValid();
        // int_type: Hop-by-hop type = 1, destination type = 2
        hdr.int_shim.int_type = 1;
        hdr.int_shim.len = INT_HEADER_LEN_WORD;
        // insert header
        hdr.int_header.setValid();
        hdr.int_header.ver = 0;
        hdr.int_header.rep = 0;
        hdr.int_header.c = 0;
        hdr.int_header.e = 0;
        hdr.int_header.m = 0;
        hdr.int_header.rsvd1 = 0;
        hdr.int_header.rsvd2 = 0;
        hdr.int_header.ins_cnt = ins_cnt;
        hdr.int_header.remaining_hop_cnt = HOP_CNT;
        hdr.int_header.instr_mask_0003 = ins_mask0003;
        hdr.int_header.instr_mask_0407 = ins_mask0407;
        hdr.int_header.instr_mask_0811 = 0;             // not support
        hdr.int_header.instr_mask_1215 = 0;             // not support

        // insert INT tail header
        hdr.int_tail.setValid();
        hdr.int_tail.next_proto = hdr.ipv4.protocol;
        hdr.int_tail.dest_port = metadata.l4_dstPort;
        hdr.int_tail.dscp = (bit<8>) hdr.ipv4.dscp;

        // 16 bytes of INT headers are added to packet INT shim header (4 bytes) + INT tail header (4 bytes) + INT metadata header (8 bytes)
        // Rest INT stack will be added by the INT transit hops
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + 16;
        // hdr.udp.length_ = hdr.udp.length_ + 16;

        // set rsvd3 by hash value
        hash(hdr.int_header.rsvd3,
            HashAlgorithm.crc16,
            ecmp_base,
            {
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.protocol,
                metadata.l4_srcPort,
                metadata.l4_dstPort
            },
            ecmp_count);
        
        // set dscp into ipv4 header
        hdr.ipv4.dscp = INT_DSCP;
    }

    table int_source_table {
        key = { 
            standard_metadata.ingress_port: exact;
        }
        actions = {
            int_source_dscp;
        }
        size = 1024;
    }

    apply {
        // call int source table
        int_source_table.apply();
    }
}

#endif