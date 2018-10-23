#ifndef __HASHPIPE__
#define __HASHPIPE__

#define TABLE_SLOTS 1024

#include "headers.p4"
#include "hash_func.p4"

control hashpipe_stage1(
    inout headers hdr,
    inout metadata_t local_metadata
){
    // store IP src
    register<bit<32>>(TABLE_SLOTS) flowTracker;
    // store packet count
    register<bit<32>>(TABLE_SLOTS) packetCounter;
    // valid bit
    register<bit<1>>(TABLE_SLOTS) validBits;
    // (additional) collision 
    // register<bit<32>>(TABLE_SLOTS) collision;

    apply {
        if(hdr.ipv4.isValid()){
            /*
                Stage 1
                - make sure always insert the new flow !
            */
            // get location (outside the action)
            a_b_hash.apply(2,3,hdr.ipv4.srcAddr,local_metadata.mIndex);
            /* 5-tuple
            if(hdr.tcp.isValid()){
            five_tuple.apply(hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol,
                hdr.tcp.srcPort, hdr.tcp.dstPort, local_metadata.mIndex);
            }
            else if(hdr.udp.isValid()){
                five_tuple.apply(hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol,
                    hdr.udp.srcPort, hdr.udp.dstPort, local_metadata.mIndex);
            }*/
            // read the key and value at the location
            flowTracker.read(local_metadata.mKeyTable, (local_metadata.mIndex)%TABLE_SLOTS);
            packetCounter.read(local_metadata.mCountTable, (local_metadata.mIndex)%TABLE_SLOTS);
            validBits.read(local_metadata.mValid, (local_metadata.mIndex)%TABLE_SLOTS);

            // check for empty location or different key
            local_metadata.mKeyTable = (local_metadata.mValid == 0) ? hdr.ipv4.srcAddr : local_metadata.mKeyTable;
            local_metadata.mDif = (local_metadata.mValid == 0) ? 0 : local_metadata.mKeyTable - hdr.ipv4.srcAddr;

            // update hash table (policy: always insert)
            flowTracker.write( local_metadata.mIndex%TABLE_SLOTS, hdr.ipv4.srcAddr );
            /*if(local_metadata.mDif == (bit<32>)0){
                packetCounter.write( local_metadata.mIndex%TABLE_SLOTS, local_metadata.mCountTable+1 );
            } else {
                packetCounter.write( local_metadata.mIndex%TABLE_SLOTS, 1 );
            }*/
            packetCounter.write( local_metadata.mIndex%TABLE_SLOTS, ((local_metadata.mDif == 0) ? local_metadata.mCountTable+1 : 1));

            validBits.write( local_metadata.mIndex%TABLE_SLOTS, 1w1 );

            // update metadata carried to the next table stage
            /*if(local_metadata.mDif == (bit<32>)0){
                local_metadata.mKeyCarried = 0;
                local_metadata.mCountCarried = 0;
            } else {
                local_metadata.mKeyCarried = local_metadata.mKeyTable;
                local_metadata.mCountCarried = local_metadata.mCountTable;
            }*/
            local_metadata.mKeyCarried = (local_metadata.mDif == 0) ? 0 : local_metadata.mKeyTable;
            local_metadata.mCountCarried = (local_metadata.mDif == 0) ? 0 : local_metadata.mCountTable;
        }
    }
}

control hashpipe_stage2(
    inout headers hdr,
    inout metadata_t local_metadata
){
    // store IP src
    register<bit<32>>(TABLE_SLOTS) flowTracker;
    // store packet count
    register<bit<32>>(TABLE_SLOTS) packetCounter;
    // valid bit
    register<bit<1>>(TABLE_SLOTS) validBits;
    // (additional) collision 
    // register<bit<32>>(TABLE_SLOTS) collision;

    apply {
        if(hdr.ipv4.isValid()){
            /*
                Stage 2
                - need to deal with conflict
                - compare with its counter
            */
            // get location 
            a_b_hash.apply(5,7, local_metadata.mKeyCarried ,local_metadata.mIndex);

            // read the key and value at the location
            flowTracker.read(local_metadata.mKeyTable, (local_metadata.mIndex)%TABLE_SLOTS);
            packetCounter.read(local_metadata.mCountTable, (local_metadata.mIndex)%TABLE_SLOTS);
            validBits.read(local_metadata.mValid, (local_metadata.mIndex)%TABLE_SLOTS);

            // check for empty location or different key
            local_metadata.mKeyTable = (local_metadata.mValid == 0) ? local_metadata.mKeyCarried : local_metadata.mKeyTable;
            local_metadata.mDif = (local_metadata.mValid == 0) ? 0 : local_metadata.mKeyTable - local_metadata.mKeyCarried;

            // update hash table
            bit<32> tKeyToWrite;
            tKeyToWrite = (local_metadata.mCountTable < local_metadata.mCountCarried) ? local_metadata.mKeyCarried : local_metadata.mKeyTable;
            flowTracker.write( local_metadata.mIndex%TABLE_SLOTS, (local_metadata.mDif == 0 ? local_metadata.mKeyTable : tKeyToWrite) );

            bit<32> tCountToWrite;
            tCountToWrite = (local_metadata.mCountTable < local_metadata.mCountCarried) ? local_metadata.mCountCarried : local_metadata.mCountTable;
            packetCounter.write( local_metadata.mIndex%TABLE_SLOTS, (local_metadata.mDif == 0 ? local_metadata.mCountTable + local_metadata.mCountCarried : tCountToWrite));

            bit<1> tBitToWrite;
            tBitToWrite = (local_metadata.mKeyCarried == 0) ? 1w0 : 1w1;
            validBits.write( local_metadata.mIndex%TABLE_SLOTS, (local_metadata.mValid == 0 ? tBitToWrite : 1));

            // - expel the key-counter pair inside current stage
            // - or current pair go to next stage
            local_metadata.mKeyCarried = (local_metadata.mDif == 0) ? 0 : ((local_metadata.mCountTable < local_metadata.mCountCarried) ? local_metadata.mKeyTable : local_metadata.mKeyCarried);
            local_metadata.mCountCarried = (local_metadata.mDif == 0) ? 0 : ((local_metadata.mCountTable < local_metadata.mCountCarried) ? local_metadata.mCountTable : local_metadata.mCountCarried);
        }
    }
}

#endif