#ifndef __HOST_METER_TABLE__
#define __HOST_METER_TABLE__

#include "headers.p4"

control host_meter_control(inout headers hdr,
                           inout metadata_t local_metadata,
                           inout standard_metadata_t standard_metadata) {
    MeterColor meter_tag = MeterColor_GREEN;
    direct_meter<MeterColor>(MeterType.bytes) host_meter;

    action read_meter() {
        host_meter.read(meter_tag);
    }

    table host_meter_table {
        key = {
            hdr.ethernet.srcAddr   : lpm;
        }
        actions = {
            read_meter();
            NoAction;
        }
        meters = host_meter;
        default_action = NoAction();
    }

    apply {
        host_meter_table.apply();
        if (meter_tag == MeterColor_RED) {
            mark_to_drop();
        }
     }
}

#endif