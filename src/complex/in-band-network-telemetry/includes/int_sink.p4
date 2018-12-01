#ifndef __INT_SINK__
#define __INT_SINK__

#include "headers.p4"
#include "int_common.p4"

control int_sink(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action process_int_sink(){
        // restore header 
        hdr.udp.dstPort = hdr.int_tail.dest_port;
        hdr.ipv4.dscp = (bit<6>)hdr.int_tail.dscp;
        
        // restore length fields of IPv4 header
        hdr.ipv4.totalLen = hdr.ipv4.totalLen - (bit<16>)((hdr.int_shim.len - (bit<8>)hdr.int_header.ins_cnt) << 2);
        hdr.ipv4.totalLen = hdr.ipv4.totalLen - 12;
        /* FIXME: udp header's length fix */

        // remove all the INT information
        hdr.int_shim.setInvalid();
        hdr.int_header.setInvalid();
        hdr.int_switch_id.pop_front(HOP_CNT);
        hdr.int_hop_latency.pop_front(HOP_CNT);
        hdr.int_q_occupancy.pop_front(HOP_CNT);
        hdr.int_tail.setInvalid();
    }

    table int_sink_table {
        key = { 
            standard_metadata.ingress_port: exact;
        }
        actions = {
            process_int_sink;
        }
        size = 1024;
    }

    apply {
        // call 
        int_sink_table.apply();
    }
}

control int_clone(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    // setup collectors/analyser address
    action set_monitor_params(bit<48> monitor_eth_dstAddr, bit<32> monitor_ip_dstAddr){
        hdr.ethernet.dstAddr = monitor_eth_dstAddr;
        hdr.ipv4.dstAddr = monitor_ip_dstAddr;
    }

    table generate_report {
        key = {
            standard_metadata.instance_type: exact;
            standard_metadata.ingress_port: exact;
        }
        actions = {
            set_monitor_params;
        }
    }

    apply {
        generate_report.apply();
    }
}

#endif