#ifndef __ARP__
#define __ARP__

control arp (
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action unknown_source(){
        // Send digest to controller
        digest<mac_learn_digest_t>((bit<32>) 1024,
            { 
                hdr.ethernet.srcAddr,
                hdr.ethernet.dstAddr,
                hdr.ethernet.etherType,
                (bit<16>)standard_metadata.ingress_port
            });
    }

    action flooding(){
        standard_metadata.mcast_grp = 1;
    }

    action arp_reply(bit<9> port){
        standard_metadata.egress_spec = port;
    }

    table arp_exact {
        key = {
            standard_metadata.ingress_port: exact;
            hdr.ethernet.dstAddr: exact;
        }
        actions = {
            unknown_source;
            flooding;
            arp_reply;
        }
        size = 1024;
        default_action = unknown_source();
    }

    apply {
        //if(hdr.ipv4.isValid()){
            arp_exact.apply();
        //}
    }
}

#endif