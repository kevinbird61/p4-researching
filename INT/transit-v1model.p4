/*
    P4.org - INT spec v1.0
    Use case: INT over TCP/UDP, deploy on INT Transit hop
    version: P4_16
    backend: bmv2 software switch
*/

// Essential library - use v1model.p4 instead
#include <core.p4>
#include <v1model.p4>

// Headers 
#include "int-header.p4"
#include "standard.p4"
#include "../CODEX/enum.p4"

// Structs
struct headers {
    ethernet_t                  ethernet;
    ipv4_t                      ipv4;
    tcp_t                       tcp;
    udp_t                       udp;
    /* INT header (shim + header) */
    int_tcpudp_shim_t                  int_shim;
    int_header_t                int_header;
    /* INT metadata */
    int_switch_id_t             int_switch_id;
    int_level1_port_ids_t       int_level1_port_ids;
    int_hop_latency_t           int_hop_latency;
    int_q_occupancy_t           int_q_occupancy;
    int_ingress_tstamp_t        int_ingress_tstamp;
    int_egress_tstamp_t         int_egress_tstamp;
    int_level2_port_ids_t       int_level2_port_ids;
    int_egress_port_tx_util_t   int_egress_port_tx_util;
}

struct empty_metadata_t {

}

/* Port id and timestamp types - defined in psa.p4 (Portable Switch Arch.) */
struct bridged_ingress_input_metadata_t {
    PortId_t    ingress_port;
    Timestamp_t ingress_timestamp;
}

/* switch internal variables for INT logic implementation */
struct int_metadata_t {
    bit<16>     insert_byte_cnt;
    bit<8>      int_hdr_word_len;
    bit<32>     switch_id;
}

struct fwd_metadata_t {
    bit<16>     l3_mtu;
    bit<16>     checksum_state;
}

struct metadata {
    bridged_ingress_input_metadata_t    bridged_istd;
    int_metadata_t                      int_metadata;
    fwd_metadata_t                      fwd_metadata;
}

error {
    BadIPv4HeaderChecksum
}

/*
    Parsers and Deparser
*/
/* Checksum verification and update of ipv4, tcp and udp are inspired by
* p4lang/p4-spec/blob/master/p4-16/psa/examples/psa-example-incremental-checksum2.p4
* For checksum related details, check the notes in the PSA example.
*/
/* This reference code processes INT Transit at egress where all
* switch metadata become available.
* Ingress doesn't need to parse or deparse INT.
*/

/*
    Parser 

    @param packet_in                        b
    @param out          H                   parsed_hdr
    @param inout        M                   meta
    @param inout        standard_metadata_t standard_metadata
*/
parser IngressParser(
    packet_in packet,
    out headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    // Checksum16() ck;

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);

        // FIXME: update checksum parameter (add ipv4 header info)
        /*
            (checksum checking mechanism)
        */

        transition select(hdr.ipv4.protocol){
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);

        // FIXME: update checksum parameter (subtract)
        /*
            (checksum checking mechanism)
        */
        
        // meta.fwd_metadata.checksum_state = ck.get_state();

        // check out dscp info 
        transition select(hdr.ipv4.dscp){
            /* &&& is a mask operator in P4_16 */
            DSCP_INT &&& DSCP_INT: parse_int_shim;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);

        // FIXME: update checksum parameter (subtract)
        /*
            (checksum checking mechanism)
        */

        // meta.fwd_metadata.checksum_state = ck.get_state();

        // end
        transition accept;
        transition select(hdr.ipv4.dscp){
            /* &&& is a mask operator in P4_16 */
            DSCP_INT &&& DSCP_INT: parse_int_shim;
            default: accept;
        }
    }

    // Now get into shim header parsing process
    state parse_int_shim {
        packet.extract(hdr.int_shim);
        
        // FIXME: update checksum parameter (subtract)
        /*
            (checksum checking mechanism)
        */

        // after parsing shim header, then go to parse int header
        transition parse_int_header;
    }

    state parse_int_header {
        packet.extract(hdr.int_header);

        // FIXME: update checksum parameter (subtract)
        /*
            (checksum checking mechanism)
        */

        // meta.fwd_metadata.checksum_state = ck.get_state();

        // end 
        transition accept;
    }
}

/*
    Verify checksum 

    @param inout H hdr
    @param inout M meta
*/
control VerifyChecksum(
    inout headers hdr,
    inout metadata meta
){
    // TODO
    apply{

    }
}


/*
    Ingress (@pipeline)

    @param inout H hdr
    @param inout M meta
    @param inout standard_metadata_t standard_metadata
*/

control Int_ingress(
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){
    action bridged_ingress_istd(){
        // FIXME: not sure its correct or not - need testcase
        meta.bridged_istd.ingress_port = standard_metadata.ingress_port;
        meta.bridged_istd.ingress_timestamp = standard_metadata.ingress_global_timestamp;
    }

    apply{
        bridged_ingress_istd();
    }
}

/**
    INT metadata insertion

    Int_metadata_insert

    @param inout H hdr
    @param in int_metadata_t int_metadata
    @param in birdged_ingress_input_metadata_t bridged_istd
    @param in standard_metadata_t standard_metadata (Modified)

*/
control Int_metadata_insert(
    inout headers hdr,
    in int_metadata_t int_metadata,
    in bridged_ingress_input_metadata_t bridged_istd,
    in standard_metadata istd 
){
    /* this reference implementation covers only INT instructions 0-3 
        0: switch id
        1: level1 port ids
        2: hop latency
        3: queue information
    */
    action int_set_header_0(){
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = int_metadata.switch_id;
    }

    action int_set_header_1(){
        hdr.int_level1_port_ids.setValid();
        hdr.int_level1_port_ids.ingress_port_id = (bit<16>) bridged_istd.ingress_port;
        hdr.int_level1_port_ids.egress_port_id = (bit<16>) istd.egress_port;
    }

    action int_set_header_2(){
        hdr.int_hop_latency.setValid();
        // hdr.int_hop_latency.hop_latency = (bit<32>) (istd.egress_timestamp - bridged_istd.ingress_timestamp);
        // Modified - using standard_metadata 
        // Notice - egress_global_timestamp/ingress_global_timestamp: bit<48>
        hdr.int_hop_latency.hop_latency = (bit<32>) (istd.egress_global_timestamp - bridged_istd.ingress_global_timestamp);
    }

    action int_set_header_3(){
        hdr.int_q_occupancy.setValid();
        // Notice: PSA doesn't support queueing metadata yet
        // assign all 1-bit value for it.
        hdr.int_q_occupancy.q_id = 0xFF;
        hdr.int_q_occupancy.q_occupancy = 0xFFFFFF;
    }

    /* action function for bits combinations, 
        0 is msb, 3 is lsb
        Each bit set indicates that corresponding INT header should be added
    */
    action int_set_header_0003_i0(){}

    action int_set_header_0003_i1(){
        int_set_header_3();
    }

    action int_set_header_0003_i2(){
        int_set_header_2();
    }

    action int_set_header_0003_i3(){
        int_set_header_3();
        int_set_header_2();
    }

    action int_set_header_0003_i4(){
        int_set_header_1();
    }

    action int_set_header_0003_i5(){
        int_set_header_3();
        int_set_header_1();
    }

    action int_set_header_0003_i6(){
        int_set_header_2();
        int_set_header_1();
    }

    action int_set_header_0003_i7(){
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
    }

    action int_set_header_0003_i8(){
        int_set_header_0();
    }

    action int_set_header_0003_i9(){
        int_set_header_3();
        int_set_header_0();
    }

    action int_set_header_0003_i10(){
        int_set_header_2();
        int_set_header_0();
    }

    action int_set_header_0003_i11(){
        int_set_header_3();
        int_set_header_2();
        int_set_header_0();
    }

    action int_set_header_0003_i12(){
        int_set_header_1();
        int_set_header_0();
    }

    action int_set_header_0003_i13(){
        int_set_header_3();
        int_set_header_1();
        int_set_header_0();
    }

    action int_set_header_0003_i14(){
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }

    action int_set_header_0003_i15(){
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }

    /* Table to process instruction bits 0-3 */
    table int_inst_0003 {
        key = {
            hdr.int_header.instruction_mask_0003: exact;
        }

        actions = {
            int_set_header_0003_i0;
            int_set_header_0003_i1;
            int_set_header_0003_i2;
            int_set_header_0003_i3;
            int_set_header_0003_i4;
            int_set_header_0003_i5;
            int_set_header_0003_i6;
            int_set_header_0003_i7;
            int_set_header_0003_i8;
            int_set_header_0003_i9;
            int_set_header_0003_i10;
            int_set_header_0003_i11;
            int_set_header_0003_i12;
            int_set_header_0003_i13;
            int_set_header_0003_i14;
            int_set_header_0003_i15;
        }
        default_action = int_set_header_0003_i0();
        size = 16;
    }

    /* Similar tables can be defined for instruction bits 4-7 and bits 8-11 */
    /* e.g. int_inst_0407, int_inst_0811 */

    apply{
        int_inst_0003.apply();
        // int_inst_0407.apply();
        // int_inst_0811.apply();
    }
}

/**
    INT outer encapsulate 

    Int_outer_encap 

    @param inout H hdr
    @param in int_metadata_t int_metadata
*/
control Int_outer_encap(
    inout headers hdr,
    in int_metadata_t int_metadata
){
    action int_update_ipv4(){
        // update total len 
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + int_metadata.insert_byte_cnt;
    }

    action int_update_shim(){
        // update shim header len
        hdr.int_shim.len = hdr.int_shim.len + int_metadata.int_hdr_word_len;
    }

    // call function - Int_outer_encap.apply()
    apply{
        if(hdr.ipv4.isValid()){
            int_update_ipv4();
        }

        /* 
            FIXME:
            Add - UDP length update if you support UDP 
        */

        if(hdr.int_shim_isValid()){
            int_update_shim();
        }
    }
}


/*
    Egress (@pipeline)

    @param inout H hdr
    @param inout M meta
    @param inout standard_metadata_t standard_metadata
*/

control Int_egress(
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata
){

    action int_hop_cnt_exceeded(){
        // mark as 1
        hdr.int_header.e = 1;
    }

    action int_mtu_limit_hit(){
        // reach the mtu limitation - mark as 1
        hdr.int_header.m = 1;
    }

    action int_hop_cnt_decrement(){
        // decrease the remaining hop cnt
        hdr.int_header.remaining_hop_cnt = hdr.int_header.remaining_hop_cnt - 1;
    }

    // transit hop switch device information assignment
    action int_transit(bit<32> switch_id, bit<16> l3_mtu){
        meta.int_metadata.switch_id = switch_id;
        meta.int_metadata.insert_byte_cnt = (bit<16>) hdr.int_header.hop_metadata_len << 2;
        meta.int_metadata.int_hdr_word_len = (bit<8>) hdr.int_header.hop_metadata_len;
        // assigne l3_mtu here!
        meta.fwd_metadata.l3_mtu = l3_mtu;
    }

    // INT table - prep
    table int_prep{
        key = {}
        actions = {
            int_transit;
        }
    }

    // Import(?) other control block
    Int_metadata_insert() int_metadata_insert;
    Int_outer_encap() int_outer_encap;

    apply{
        if(hdr.int_header.isValid()){
            if(hdr.int_header.remaining_hop_cnt == 0 || 
                hdr.int_header.e == 1){
                    // call exceeded action
                    int_hop_cnt_exceeded();
                }
                else if((hdr.int_header.instruction_mask_0811 ++ 
                    hdr.int_header.instruction_mask_1215) & 8w0xFE == 0){
                    /*
                        v1.0 spec allows "2" options for handling unsupported
                        INT instructions. This example code skips the entire hop
                        if any unsupported bit (bit 8~14 in v1.0 spec) is set.
                    */
                    // apply match/action table 
                    int_prep.apply();
                    // check MTU limit
                    // - Who assign fwd_metadata.l3_mtu ?
                    if(hdr.ipv4.totalLen + meta.int_metadata.insert_byte_cnt > meta.fwd_metadata.l3_mtu){
                        int_mtu_limit_hit();
                    }else{
                        // update cnt (action)
                        int_hop_cnt_decrement();
                        // insert metdata (action)
                        // modified - using "standard_metadata" instead
                        int_metadata_insert.apply(
                            hdr,
                            meta.int_metadata,
                            meta.bridged_istd,
                            standard_metadata
                        );
                        // encap shim & ipv4 ...
                        int_outer_encap.apply(
                            hdr,
                            meta.int_metadata
                        );
                    }
                }
        }
    }
}

/* ?
    Some place need to change - how to call egress.apply()/ingress.apply() ?
*/

/*
    Compute checksum 

    @param inout H hdr
    @param inout M meta
*/
control ComputeChecksum(
    inout headers hdr,
    inout metadata meta
){
    // TODO
    apply{

    }
}

/*
    Deparser (@deparser)

    @param packet_out b
    @param in H hdr
*/

control EgressDeparser(
    packet_out b,
    in headers hdr
){
    // Checksum16() ck;

    apply{
        if(hdr.ipv4.isValid()){
            // TODO: 
            // checksum 
        }
    }

    // TODO: 
    // ck.set_state(meta.fwd_metadata.checksum_state);

    // Add back relevant header fields, including new INT metadata
    if(hdr.ipv4.isValid()){
        // TODO: update checksum (add)
    }

    if(hdr.int_shim.isValid()){
        // TODO: update checksum (add)
    }

    if(hdr.int_header.isValid()){
        // TODO: update checksum (add)
    }

    if (hdr.int_switch_id.isValid()) {
        // TODO: update checksum (add)
    }

    if (hdr.int_level1_port_ids.isValid()) {
        // TODO: update checksum (add)
    }

    if (hdr.int_hop_latency.isValid()) {
        // TODO: update checksum (add)
    }

    if (hdr.int_q_occupancy.isValid()) {
        // TODO: update checksum (add)
    }

    if (hdr.int_ingress_tstamp.isValid()) {
        // TODO: update checksum (add)
    }

    if (hdr.int_egress_tstamp.isValid()) {
        // TODO: update checksum (add)
    }

    if (hdr.int_level2_port_ids.isValid()) {
        // TODO: update checksum (add)
    }

    if (hdr.int_egress_port_tx_util.isValid()){
        // TODO: update checksum (add)
    }

    if (hdr.tcp.isValid()){
        // TODO: update checksum (add)
    }

    if(hdr.udp.isValid()){
        // TODO: update checksum (add)
    }

    // emit the header to construct packet
    packet.emit(hdr.ethernet);
    packet.emit(hdr.ipv4);
    packet.emit(hdr.tcp);
    packet.emit(hdr.udp);
    packet.emit(hdr.int_shim);
    packet.emit(hdr.int_header);
    packet.emit(hdr.int_switch_id);
    packet.emit(hdr.int_level1_port_ids);
    packet.emit(hdr.int_hop_latency);
    packet.emit(hdr.int_q_occupancy);
    packet.emit(hdr.int_ingress_tstamp);
    packet.emit(hdr.int_egress_tstamp);
    packet.emit(hdr.int_level2_port_ids);
    packet.emit(hdr.int_egress_port_tx_util);
}

// Form our switch architecture
V1Switch(
IngressParser(),
VerifyChecksum(),
Int_ingress(),
Int_egress(),
ComputeChecksum(),
EgressDeparser()
) main;