#ifndef __INT_COMMON__
#define __INT_COMMON__

#include "headers.p4"

control Int_metadata_insert(
    inout headers_t hdr,
    in int_metadata_t int_metadata,
    inout standard_metadata_t standard_metadata
){
    action int_set_header_0() { 
        // switch id
        //hdr.int_switch_id.setValid();
        hdr.int_switch_id.push_front(1);
        hdr.int_switch_id[0].switch_id = int_metadata.switch_id;
    }
    action int_set_header_1() {  
        // ingress and egress ports
        //hdr.int_port_ids.setValid();
        hdr.int_port_ids.push_front(1);
        hdr.int_port_ids[0].ingress_port_id =(bit<16>) standard_metadata.ingress_port;
        hdr.int_port_ids[0].egress_port_id =(bit<16>) standard_metadata.egress_port;


    }
    action int_set_header_2() { 
        // hop latency
        //hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.push_front(1);
        hdr.int_hop_latency[0].hop_latency = (bit<32>) standard_metadata.deq_timedelta; //the time, in microseconds, that the packet spent in the queue.

    }
    action int_set_header_3() { 
        // q occupency
        //hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.push_front(1);
        hdr.int_q_occupancy[0].q_id = 0; // assuming qid is always 0 //(bit<8>) standard_metadata.egress_qid; // egress qid is not yet exposed in v1model.p4
        hdr.int_q_occupancy[0].q_occupancy = (bit<24>) standard_metadata.deq_qdepth; //the depth of queue when the packet was dequeued.


    }
    action int_set_header_4() { 
        // ingress_timestamp
        //hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_ts.push_front(1);
        hdr.int_ingress_ts[0].ingress_ts = (bit<32>) standard_metadata.enq_timestamp;

    }
    action int_set_header_5() { 
        // egress_timestamp
        //hdr.int_egress_tstamp.setValid();
        hdr.int_egress_ts.push_front(1);
        hdr.int_egress_ts[0].egress_ts =(bit<32>) standard_metadata.enq_timestamp + (bit<32>) standard_metadata.deq_timedelta;

    }
    action int_set_header_6() { 
        // q_congestion
        // TODO: implement queue congestion support in BMv2
        // TODO: update egress queue ID
        //hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.push_front(1);
        hdr.int_q_congestion[0].q_id =0;// (bit<8>) standard_metadata.egress_qid;
        hdr.int_q_congestion[0].q_congestion =0;// (bit<24>) queueing_metadata.deq_congestion;

    }
    action int_set_header_7() { 
        // egress_port_tx_utilization
        // TODO: implement tx utilization support in BMv2
        // hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.push_front(1);
        hdr.int_egress_port_tx_util[0].egress_port_tx_util = 0;// (bit<32>) queueing_metadata.tx_utilization;
    }

    /* action function for bits 0-3 */
    action int_set_header_0003_i0() {
    }
    action int_set_header_0003_i1() {
        int_set_header_3();
    }
    action int_set_header_0003_i2() {
        int_set_header_2();
    }
    action int_set_header_0003_i3() {
        int_set_header_3();
        int_set_header_2();
    }
    action int_set_header_0003_i4() {
        int_set_header_1();
    }
    action int_set_header_0003_i5() {
        int_set_header_3();
        int_set_header_1();
    }
    action int_set_header_0003_i6() {
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i7() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i8() {
        int_set_header_0();
    }
    action int_set_header_0003_i9() {
        int_set_header_3();
        int_set_header_0();
    }
    action int_set_header_0003_i10() {
        int_set_header_2();
        int_set_header_0();
    }
    action int_set_header_0003_i11() {
        int_set_header_0();
        int_set_header_2();
        int_set_header_3();
    }
    action int_set_header_0003_i12() {
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i13() {
        int_set_header_3();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i14() {
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i15() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }
    
    /* action function for bits 4-7 */
    action int_set_header_0407_i0() {
    }
    action int_set_header_0407_i1() {
        int_set_header_7();
    }
    action int_set_header_0407_i2() {
        int_set_header_6();
    }
    action int_set_header_0407_i3() {
        int_set_header_7();
        int_set_header_6();
    }
    action int_set_header_0407_i4() {
        int_set_header_5();
    }
    action int_set_header_0407_i5() {
        int_set_header_7();
        int_set_header_5();
    }
    action int_set_header_0407_i6() {
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i7() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i8() {
        int_set_header_4();
    }
    action int_set_header_0407_i9() {
        int_set_header_7();
        int_set_header_4();
    }
    action int_set_header_0407_i10() {
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i11() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i12() {
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i13() {
        int_set_header_7();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i14() {
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i15() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }

    // INT instruction table: 00~03
    table int_inst_0003 {
        key = {
            hdr.int_header.instr_mask_0003: exact;
        }
        actions = {
            int_set_header_0003_i0;
            int_set_header_0003_i1;
            int_set_header_0003_i2;
            int_set_header_0003_i3;
            int_set_header_0003_i4;
            int_set_header_0003_i5;
            int_set_header_0003_i6;
            int_set_header_0003_i7;
            int_set_header_0003_i8;
            int_set_header_0003_i9;
            int_set_header_0003_i10;
            int_set_header_0003_i11;
            int_set_header_0003_i12;
            int_set_header_0003_i13;
            int_set_header_0003_i14;
            int_set_header_0003_i15;
        }
        default_action = int_set_header_0003_i0();
        size=16;
    }

    // INT instruction table: 04~07
    table int_inst_0407 {
        key = {
            hdr.int_header.instr_mask_0407: exact;
        }
        actions = {
            int_set_header_0407_i0;
            int_set_header_0407_i1;
            int_set_header_0407_i2;
            int_set_header_0407_i3;
            int_set_header_0407_i4;
            int_set_header_0407_i5;
            int_set_header_0407_i6;
            int_set_header_0407_i7;
            int_set_header_0407_i8;
            int_set_header_0407_i9;
            int_set_header_0407_i10;
            int_set_header_0407_i11;
            int_set_header_0407_i12;
            int_set_header_0407_i13;
            int_set_header_0407_i14;
            int_set_header_0407_i15;
        }
        default_action = int_set_header_0407_i0();
        size=16;
    }

    // apply 
    apply {
        int_inst_0003.apply();
        int_inst_0407.apply();
    }
}

control Int_outer_encap(
    inout headers_t hdr,
    in int_metadata_t int_metadata
){
    action int_update_ipv4(){
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + int_metadata.insert_byte_cnt;
        // hdr.udp.length_ = hdr.udp.length_ + int_metadata.insert_byte_cnt;
    }

    action int_update_shim(){
        hdr.int_shim.len = hdr.int_shim.len + int_metadata.int_hdr_word_len;
    }

    apply {
        if(hdr.ipv4.isValid()){
            int_update_ipv4();
        }
        if(hdr.int_shim.isValid()){
            int_update_shim();
        }
    }
}

#endif