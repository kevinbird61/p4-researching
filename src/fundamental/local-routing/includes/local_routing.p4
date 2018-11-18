#ifndef __LOCAL_ROUTING__
#define __LOCAL_ROUTING__

#include "headers.p4"
#include "actions.p4"

#define TABLE_SLOT 1024

control local_routing_control(
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    /* 
        using register to maintain local routing table 

        | key           | value       |
        | ============= | =========== |
        | 5-tuple hash  | egress port |
    */
    register<bit<9>>(TABLE_SLOT) RoutingTable;
    register<bit<1>>(TABLE_SLOT) ValidBit;

    action get_index(){
        // Hash the 3-tuple, which set the key range: 0~1024
        hash(
            metadata.hash_key,
            HashAlgorithm.crc16,
            (bit<32>)0,
            {
                hdr.ipv4.dstAddr
            },
            (bit<32>)TABLE_SLOT
        );
    }

    action local_lookup(){
        // hash first to get table index
        get_index();
        // check valid bit
        bit<1> valid_bit;
        // temp variable
        bit<9> get_port;
        // srcAddr hash
        bit<32> src_hash_key;

        // read value from it
        ValidBit.read(valid_bit, metadata.hash_key);
        RoutingTable.read(get_port, metadata.hash_key);

        // hash 
        hash(
            src_hash_key,
            HashAlgorithm.crc16,
            (bit<32>)0,
            {
                hdr.ipv4.srcAddr
            },
            (bit<32>)TABLE_SLOT
        );

        // set egress spec (origin or the new one)
        standard_metadata.egress_spec = ((valid_bit == (bit<1>) 1w0) ? standard_metadata.egress_spec : get_port);

        // write back into register
        ValidBit.write(src_hash_key, (bit<1>)1w1);
        RoutingTable.write(src_hash_key, standard_metadata.ingress_port);
    }

    table local_routing_table {
        key = {
        }
        actions = {
            local_lookup;
        }
        size=1024;
        default_action=local_lookup();
    }

    apply{
        if(hdr.ipv4.isValid()){
            local_routing_table.apply();
        }
    }
}

#endif