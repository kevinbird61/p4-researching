#ifndef __LOCAL_LEARNING_FIREWALL__
#define __LOCAL_LEARNING_FIREWALL__

/*
    Receive the "Notify Packet" sent from the other switch.
    Use those information to update, extend the table of local learning firewall
*/

#include "headers.p4"

control local_firewall_func (
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    register<bit<32>>(1024) local_firewall_state;

    action update_and_match(){
        /* update the correspond entry in local_firewall_state */
        bit<32> flow_id;
        bit<32> port;
        // Get hash key
        hash(flow_id,
            HashAlgorithm.crc16,
            (bit<32>)0,
            {
                hdr.notify.malform_srcAddr
            },
            (bit<32>)1023);
        
        // read from local_firewall_state
        local_firewall_state.read(port, flow_id);
        // set the value to 1
        port = 32w1;
        local_firewall_state.write(flow_id, port);
        // set invalid
        hdr.notify.setInvalid();
        // set mark_drop bit
        metadata.mark_drop = 1w1;
    }

    action match(){
        bit<32> flow_id;
        bit<32> port;
        // Get hash key
        hash(flow_id,
            HashAlgorithm.crc16,
            (bit<32>)0,
            {
                hdr.ipv4.srcAddr
            },
            (bit<32>)1023);
        // read from local_firewall_state
        local_firewall_state.read(port, flow_id);
        // set mark_drop bit
        metadata.mark_drop = ( port == 32w1 ? 1w1 : 1w0);

        // for destination check
        hash(flow_id,
            HashAlgorithm.crc16,
            (bit<32>)0,
            {
                hdr.ipv4.dstAddr
            },
            (bit<32>)1023);
        // read from local_firewall_state
        local_firewall_state.read(port, flow_id);
        // set mark_drop bit
        metadata.mark_drop = ( port == 32w1 ? 1w1 : 1w0);
    }

    apply {
        if(hdr.notify.isValid()){
            update_and_match();
        }
        match();
        if(metadata.mark_drop == 1w1){
            mark_to_drop();
        }
    }
}

#endif