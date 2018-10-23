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

    // per packet id 
    bit<32> packet_index;
    // temp variables
    bit<32> mKeyTable;
    bit<32> mCountTable;
    bit<32> mDif;
    bit<1>  mValid;

    apply {
        if(hdr.ipv4.isValid()){
            // get "packet_index" 
            if(hdr.tcp.isValid()){
                five_tuple.apply(hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol,
                    hdr.tcp.srcPort, hdr.tcp.dstPort, packet_index);
            }
            else if(hdr.udp.isValid()){
                five_tuple.apply(hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol,
                    hdr.udp.srcPort, hdr.udp.dstPort, packet_index);
            }

            // read the key and value at the location
            flowTracker.read(mKeyTable, packet_index%TABLE_SLOTS);
            packetCounter.read(mCountTable, packet_index%TABLE_SLOTS);
            validBits.read(mValid, packet_index%TABLE_SLOTS);

            // check for empty location or different key
            mKeyTable = (mValid == 0) ? hdr.ipv4.srcAddr : mKeyTable;
            mDif = (mValid == 0) ? 0 : mKeyTable - hdr.ipv4.srcAddr;

            // update hash table (policy: always insert)
            flowTracker.write(packet_index%TABLE_SLOTS, hdr.ipv4.srcAddr);
            if(mDif == (bit<32>)0){
                packetCounter.write(packet_index%TABLE_SLOTS, mCountTable+1);
            } else {
                packetCounter.write(packet_index%TABLE_SLOTS, 1);
            }
            validBits.write(packet_index%TABLE_SLOTS, 1w1);

            // FIXME: update metadata carried to the next table stage
            if(mDif == (bit<32>)0){
                // metadata.mKeyCarried = 0;
                // metadata.mCountCarried = 0;
            } else {
                // metadata.mKeyCarried = mKeyTable;
                // metadata.mCountCarried = mCountTable;
            }
        }
    }
}

#endif