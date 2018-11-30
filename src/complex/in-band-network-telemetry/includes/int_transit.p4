#ifndef __INT_TRANSIT__
#define __INT_TRANSIT__

#include "headers.p4"
#include "int_common.p4"

control int_transit(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    table int_transit_table {
        key = { 
            standard_metadata.ingress_port: exact;
        }
        actions = {
            
        }
        size = 1024;
    }

    apply {
        // call 
        int_transit_table.apply();
    }
}

control int_transit_egress(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action int_transit_e(bit<32> switch_id){
        metadata.int_metadata.switch_id = switch_id;
        metadata.int_metadata.insert_byte_cnt = (bit<16>) hdr.int_header.ins_cnt << 2;
        metadata.int_metadata.int_hdr_word_len = (bit<8>) hdr.int_header.ins_cnt;
    }

    table int_prep {
        key={}
        actions={
            int_transit_e;
        }
        size=128;
    }

    action int_hop_cnt_decrement(){
        hdr.int_header.remaining_hop_cnt = hdr.int_header.remaining_hop_cnt - 1;
    }

    action int_hop_cnt_exceeded(){
        hdr.int_header.e = 1; // represent "hop count is exceeded!"
    }

    Int_metadata_insert() int_metadata_insert;
    Int_outer_encap() int_outer_encap;

    apply{
        if(hdr.int_header.isValid()){
            if(hdr.int_header.remaining_hop_cnt != 0 && hdr.int_header.e == 0){
                // call decrement function
                int_hop_cnt_decrement();
                // transit table
                int_prep.apply();
                int_metadata_insert.apply(hdr, metadata.int_metadata, standard_metadata);
                int_outer_encap.apply(hdr, metadata.int_metadata);
            } else {
                int_hop_cnt_exceeded();
            }
        }
    }
}

#endif