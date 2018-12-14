#ifndef __SKETCH__
#define __SKETCH__

#include "headers.p4"
#include "actions.p4"

#define TABLE_SLOT 512

control traffic_sketch(
    inout headers_t hdr,
    inout metadata_t metadata, 
    inout standard_metadata_t standard_metadata
){
    /*
        using register to maintain sketch table

        | key       | value         |
        | ========= | ============= |

        FlowCount:
        | flow id   | count         | (bit<32>)

        LastSeen:
        | flow id   | timestamp(ns) | (bit<48>)


    */
    register<bit<32>>(TABLE_SLOT) FlowCount;
    register<bit<48>>(TABLE_SLOT) LastSeen;
    register<bit<48>>(TABLE_SLOT) DeltaTime; // Current - LastSeen

    action sketching(){
        // Get index (Using 5 tuple)
        hash(
            metadata.flow_id, 
            HashAlgorithm.crc16,
            (bit<32>)0,
            {
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.protocol,
                metadata.l4_srcPort,
                metadata.l4_dstPort
            },
            (bit<32>)TABLE_SLOT
        );

        // Read from FlowCount
        FlowCount.read(metadata.flow_count_val, metadata.flow_id);
        // Then writeback 
        FlowCount.write(metadata.flow_id, metadata.flow_count_val + 32w1);

        // Read the LastSeen value
        LastSeen.read(metadata.last_seen_val, metadata.flow_id);
        // Write into Delta 
        DeltaTime.write(metadata.flow_id, standard_metadata.ingress_global_timestamp - metadata.last_seen_val);
        // Update LastSeen 
        LastSeen.write(metadata.flow_id, standard_metadata.ingress_global_timestamp);
        
    }

    apply {
        sketching();
    }
}

#endif