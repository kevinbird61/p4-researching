#ifndef __NETCACHE__
#define __NETCACHE__

#include "headers.p4"

#define TABLE_SLOTS 1024
#define HOTKEY_THRES 1000

control netcache_keyValue(
    inout headers hdr,
    inout metadata_t local_metadata,
    inout standard_metadata_t standard_metadata
){
    /*
        Declare key-value cache, stats

        * key-value store cache (register)
        * heavy-hitter detector 
        * counters for Cache keys

        (Query statistic)
    */
    register<bit<32>>(TABLE_SLOTS) KVCache;
    register<bit<32>>(TABLE_SLOTS) Stats;
    register<bit<1>>(TABLE_SLOTS) KVCache_validBit;

    register<bit<32>>(TABLE_SLOTS) HHD; // Heavy hitter detector


    action getOp(){
        // valid
        bit<1>  validBit;
        // count (stats)
        bit<32> cnt;
        // read validbit from KVCache
        KVCache_validBit.read(validBit, hdr.netcache.key);
        if(validBit == 1w1){
            // if valid, then read the value
            KVCache.read(hdr.netcache.value, hdr.netcache.key);
            // stats count
            Stats.read(cnt, hdr.netcache.key);
            Stats.write(hdr.netcache.key, cnt + 32w1);
        }
        else{
            // not found 
            // FIXME: here only use validBit to represent 
            // hit() and valid()
            
            // 1. Heavy Hitter count 
            // FIXME: key range ? Can't be the same size as KVCache
            HHD.read(cnt, hdr.netcache.key);
            cnt = cnt + 32w1;
            // 2. Check if it is hot key?
            if(cnt > HOTKEY_THRES){
                // is hot key, report
                // TODO: using packetIn to report
            }
            HHD.write(hdr.netcache.key, cnt);
        }
        

    }

    action putOp(){

    }

    action delOp(){

    }

    table cache_lookup {
        key = {
            hdr.netcache.opcode: exact;
        }
        actions = {
            getOp;
            putOp;
            delOp;
            _drop;
            NoAction;
        }
        size=1024;
        default_action=NoAction();
    }

    apply {
        if(hdr.netcache.isValid()){
            cache_lookup.apply();
        }
    }
}

#endif