#ifndef __NETCACHE__
#define __NETCACHE__

#include "headers.p4"

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

    action getOp(){

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