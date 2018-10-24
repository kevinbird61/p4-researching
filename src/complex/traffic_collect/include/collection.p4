#ifndef __COLLECTION__
#define __COLLECTION__

#define TABLE_SLOTS 1024
#include "headers.p4"

control traffic_collection(
    in headers hdr,
    in metadata_t local_metadata,
    in standard_metadata_t standard_metadata
){
    /*
        Stateful Memory for traffic classified collection
    */
    // time interval
    register<bit<32>>(TABLE_SLOTS) time_interval;
    // deq/enq length record
    register<bit<32>>(TABLE_SLOTS) enq_length;
    register<bit<32>>(TABLE_SLOTS) deq_length;
    // packet size
    register<bit<32>>(TABLE_SLOTS) packet_size;

    apply {
        if(hdr.ipv4.isValid()){
            // get index 
            bit<32> mIndex;
            // using 3-tuple to do hash
            hash(mIndex, HashAlgorithm.crc32, 32w0, {
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.protocol
            }, 32w32);
            // mod 
            mIndex = mIndex%TABLE_SLOTS;
            /* TODO: Checking collision */
            // read and store time interval (dep - enq) with avg
            bit<32> ReadFromTimeTable;
            time_interval.read(ReadFromTimeTable, mIndex);
            time_interval.write(mIndex, (ReadFromTimeTable + standard_metadata.deq_timedelta)/2 );
            // read and store queueing length back with avg
            bit<32> ReadFromLen;
            enq_length.read(ReadFromLen, mIndex);
            enq_length.write(mIndex, (ReadFromLen + (bit<32>)standard_metadata.enq_qdepth)/2 );
            deq_length.read(ReadFromLen, mIndex); // reuse same variable
            deq_length.write(mIndex, (ReadFromLen + (bit<32>)standard_metadata.deq_qdepth)/2 );
            // get packet size
            bit<32> ReadPktSize;
            packet_size.read(ReadPktSize, mIndex);
            packet_size.write(mIndex, (ReadPktSize + (bit<32>)hdr.ipv4.totalLen)/2 );

            /* 
                TODO:
                Using Digest/Packet_in to send the result,
                Or just store them into register (stateful memory)
            */            
        }
        
    }
}

#endif