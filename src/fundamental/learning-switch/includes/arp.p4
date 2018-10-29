#ifndef __ARP__
#define __ARP__

control arp (
    inout headers_t hdr,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
){
    action send_to_cpu(){
        standard_metadata.egress_spec = CPU_PORT;
        hdr.packet_in.setValid();
        hdr.packet_in.ingress_port = standard_metadata.ingress_port;
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
            send_to_cpu;
            flooding;
            arp_reply;
        }
        size = 1024;
        default_action = send_to_cpu();
    }

    apply {
        if(standard_metadata.ingress_port == CPU_PORT){
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
            standard_metadata.mcast_grp = hdr.packet_out.mcast_grp;
            hdr.packet_out.setInvalid();
        } else {
            arp_exact.apply();
        }
    }
}

#endif