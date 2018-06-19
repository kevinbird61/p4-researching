# V1Switch Architecture

* Architecture `v1model.p4`
    * one `parser` and five `control block`
    * So need to merge the ingress parser and egress parser together.
```p4
// Architecture.
// M should be a struct of structs
// H should be a struct of headers or stacks

parser Parser<H, M>(packet_in b,
                    out H parsedHdr,
                    inout M meta,
                    inout standard_metadata_t standard_metadata);

/* The only legal statements in the implementation of the
VerifyChecksum control are: block statements, calls to the
verify_checksum and verify_checksum_with_payload methods,
and return statements. */
control VerifyChecksum<H, M>(inout H hdr,
                             inout M meta);
@pipeline
control Ingress<H, M>(inout H hdr,
                      inout M meta,
                      inout standard_metadata_t standard_metadata);
@pipeline
control Egress<H, M>(inout H hdr,
                     inout M meta,
                     inout standard_metadata_t standard_metadata);

/* The only legal statements in the implementation of the
ComputeChecksum control are: block statements, calls to the
update_checksum and update_checksum_with_payload methods,
and return statements. */
control ComputeChecksum<H, M>(inout H hdr,
                              inout M meta);
@deparser
control Deparser<H>(packet_out b, in H hdr);

package V1Switch<H, M>(Parser<H, M> p,
                       VerifyChecksum<H, M> vr,
                       Ingress<H, M> ig,
                       Egress<H, M> eg,
                       ComputeChecksum<H, M> ck,
                       Deparser<H> dep
                       );
```

* standard_metadata: 

```p4
@metadata @name("standard_metadata")
struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<32> clone_spec;
    bit<32> instance_type;
    bit<1>  drop;
    bit<16> recirculate_port;
    bit<32> packet_length;
    //
    // @alias is used to generate the field_alias section of the BMV2 JSON.
    // Field alias creates a mapping from the metadata name in P4 program to
    // the behavioral model's internal metadata name. Here we use it to
    // expose all metadata supported by simple switch to the user through
    // standard_metadata_t.
    //
    // flattening fields that exist in bmv2-ss
    // queueing metadata
    @alias("queueing_metadata.enq_timestamp") bit<32> enq_timestamp;
    @alias("queueing_metadata.enq_qdepth")    bit<19> enq_qdepth;
    @alias("queueing_metadata.deq_timedelta") bit<32> deq_timedelta;
    @alias("queueing_metadata.deq_qdepth")    bit<19> deq_qdepth;
    // intrinsic metadata
    @alias("intrinsic_metadata.ingress_global_timestamp") bit<48> ingress_global_timestamp;
    @alias("intrinsic_metadata.egress_global_timestamp") bit<48> egress_global_timestamp;
    @alias("intrinsic_metadata.lf_field_list") bit<32> lf_field_list;
    @alias("intrinsic_metadata.mcast_grp")     bit<16> mcast_grp;
    @alias("intrinsic_metadata.resubmit_flag") bit<32> resubmit_flag;
    @alias("intrinsic_metadata.egress_rid")    bit<16> egress_rid;
    /// Indicates that a verify_checksum() method has failed.
    bit<1>  checksum_error;
    @alias("intrinsic_metadata.recirculate_flag") bit<32> recirculate_flag;
}
```

* [v1model.p4 - Source code](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)