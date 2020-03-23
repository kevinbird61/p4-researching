#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import argparse, grpc, os, sys
import  threading
from time import sleep
import time

# set our lib path
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
        '../../../utils/'))
# And then we import
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

def setDefaultDrop(p4info_helper,ingress_sw):
    """
        設定 drop 
    """
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.ipv4_lpm",
        default_action=True,
        action_name="Basic_ingress.drop",
        action_params={})
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed Default Drop Rule on %s" % ingress_sw.name

def writeHostForwardRules(p4info_helper,ingress_sw,
    dst_eth_addr,port,dst_ip_addr):
    """
        Install rules:
        
        做到原本 sx-runtime.json 的工作
            p4info_helper:  the P4Info helper
            ingress_sw:     the ingress switch connection
            dst_eth_addr:   the destination Ethernet address to write in the egress rule
            port:           port of switch 
            dst_ip_addr:    the destination IP to match in the ingress rule
    """

    # 1. Ingress rule
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,32)
        },
        action_name="Basic_ingress.host_forward",
        action_params={
            "dstAddr": dst_eth_addr,
            "port": port
        })
    # write into ingress of target sw
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed host ingress tunnel rule on %s" % ingress_sw.name

def writeL3ForwardRules(p4info_helper,ingress_sw,port,dst_ip_addr, prefix):
    """
        Install rules:
        
        做到原本 sx-runtime.json 的工作
            p4info_helper:  the P4Info helper
            ingress_sw:     the ingress switch connection
            port:           port of switch 
            dst_ip_addr:    the destination IP to match in the ingress rule
    """

    # 1. Ingress rule
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,prefix)
        },
        action_name="Basic_ingress.l3_forward",
        action_params={
            "port": port
        })
    # write into ingress of target sw
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed l3 ingress tunnel rule on %s" % ingress_sw.name

def writeDropForwardRules(p4info_helper,ingress_sw,port):
    """
        Install rules:
        
        做到原本 sx-runtime.json 的工作
            p4info_helper:  the P4Info helper
            ingress_sw:     the ingress switch connection
            port:           port of switch 
            dst_ip_addr:    the destination IP to match in the ingress rule
    """

    # 1. Ingress rule
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.syn_drop",
        match_fields={
            "standard_metadata.ingress_port": port,
            "hdr.ipv4.dstAddr":("10.0.1.1",32)
        },
        action_name="Basic_ingress.drop",
    )
    # write into ingress of target sw
    ingress_sw.WriteTableEntry(table_entry)
    print "Write drop rule on %s port %s" % (ingress_sw.name,port)

def writeSynAckCountRules(p4info_helper,ingress_sw,dst_ip_addr,prefix,index):
    """
        Install rules:
        Counting the packets of an entry
            p4info_helper:  the P4Info helper
            ingress_sw:     the ingress switch connection
            dst_ip_addr:    the IP to match in the ingress rule
    """

    # synack_entry
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.synack_entry",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,prefix)
        },
        action_name="Basic_ingress.synack_counting",
        action_params={
            "index": index
        })
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed Syn Ack counting rule of %s/%s in %s" % (dst_ip_addr,prefix,index)

    # ack_entry
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.ack_entry",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,prefix)
        },
        action_name="Basic_ingress.ack_counting",
        action_params={
            "index": index
        })
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed Ack counting rule of %s/%s" % (dst_ip_addr,prefix)

def deleteSynAckCountRules(p4info_helper,ingress_sw,dst_ip_addr,prefix, index):
    """
        Install rules:
        Counting the packets of an entry
            p4info_helper:  the P4Info helper
            ingress_sw:     the ingress switch connection
            dst_ip_addr:    the IP to match in the ingress rule
    """

    # synack_entry
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.synack_entry",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,prefix)
        },
        action_name="Basic_ingress.synack_counting",
        action_params={
            "index": index
        })
    ingress_sw.DeleteTableEntry(table_entry)
    print "Deleted SynAck count rule of %s/%s" % (dst_ip_addr,prefix)

    # ack_entry
    table_entry = p4info_helper.buildTableEntry(
        table_name="Basic_ingress.ack_entry",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,prefix)
        },
        action_name="Basic_ingress.ack_counting",
        action_params={
            "index": index
        })
    ingress_sw.DeleteTableEntry(table_entry)
    print "Deleted Ack count rule of %s/%s" % (dst_ip_addr,prefix)

def SendDigestEntry(p4info_helper, sw, digest_name=None):
    digest_entry = p4info_helper.buildDigestEntry(digest_name=digest_name)
    sw.WriteDigestEntry(digest_entry)
    print "Sent DigestEntry via P4Runtime."

def readTableRules(p4info_helper, sw):
    """
        Reads the table entries from all tables on the switch.
        Args:
            p4info_helper:  the P4Info helper
            sw:             the switch connection
    """
    print '\n----- Reading table rules for %s ------' % sw.name
    for response in sw.ReadTableEntries():
        for entity in response.entities:
            entry = entity.table_entry
            # TOOD:
            # use the p4info_helper to translate the IDs in the entry to names
            table_name = p4info_helper.get_tables_name(entry.table_id)
            print '%s: ' % table_name,
            for m in entry.match:
                print p4info_helper.get_match_field_name(table_name, m.field_id)
                print '%r' % (p4info_helper.get_match_field_value(m),),
            action = entry.action.action
            action_name = p4info_helper.get_actions_name(action.action_id)
            print '->', action_name,
            for p in action.params:
                print p4info_helper.get_action_param_name(action_name, p.param_id),
                print '%r' % p.value
            print

def printCounter(p4info_helper, sw, counter_name, index):
    """
        讀取指定的 counter 於指定 switch 上的 index
        於這支範例程式中，index 是利用 tunnel ID 來標記
        若 index 為 0，當將會 return 所有該 counter 的 values
        Args:
            p4info_helper:  the P4Info Helper
            sw:             the switch connection
            counter_name:   the name of the counter from the P4 program
            index:          the counter index (in our case, the Tunnel ID)
    """
    for response in sw.ReadCounters(p4info_helper.get_counters_id(counter_name), index):
        for entity in response.entities:
            counter = entity.counter_entry
            print "[SW: %s][Cnt: %s][Port: %d]: %d packets (%d bytes)" % (sw.name,counter_name, index,counter.data.packet_count, counter.data.byte_count)

def testingFunc(p4info_helper, sw, counter_name):
    while 1:
        printCounter(p4info_helper, sw, counter_name, 2)
        time.sleep(30)

def readRegister(p4info_helper, sw, register_name, index):
    for response in sw.ReadRegister(p4info_helper.get_registers_id(register_name), index):
        for entity in response.entities:
            register = entity.register_entry
            # P4Data usage in register_entry (because we using bit<32> as register data type, so we use bitstring)
            print "[SW: %s][Reg: %s] info: %s" % (sw.name, register_name, register.data.bitstring)

def printGrpcError(e):
    print "gRPC Error: ", e.details(),
    status_code = e.code()
    print "(%s)" % status_code.name,
    # detail about sys.exc_info - https://docs.python.org/2/library/sys.html#sys.exc_info
    traceback = sys.exc_info()[2]
    print "[%s:%s]" % (traceback.tb_frame.f_code.co_filename, traceback.tb_lineno)

def prettify(IP_string):
    return '.'.join('%d' % ord(b) for b in IP_string)

def int_prettify(int_string):
    return int(''.join('%d' % ord(b) for b in int_string))

def main(p4info_file_path, bmv2_file_path):
    # Instantiate a P4Runtime helper from the p4info file
    # - then need to read from the file compile from P4 Program, which call .p4info
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    try:
        """
            建立與範例當中使用到的兩個 switch - s1, s2
            使用的是 P4Runtime gRPC 的連線。
            並且 dump 所有的 P4Runtime 訊息，並送到 switch 上以 txt 格式做儲存
            - 以這邊 P4 的封裝來說， port no 起始從 50051 開始
         """
        s1 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s1',
            address='127.0.0.1:50051',
            device_id=0,
            proto_dump_file='logs/s1-p4runtime-requests.txt')
        s2 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s2',
            address='127.0.0.1:50052',
            device_id=1,
            proto_dump_file='logs/s2-p4runtime-requests.txt')
        s3 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s3",
            address='127.0.0.1:50053',
            device_id=2,
            proto_dump_file='logs/s3-p4runtime-requests.txt')
        s4 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s4',
            address='127.0.0.1:50054',
            device_id=3,
            proto_dump_file='logs/s4-p4runtime-requests.txt')
        s5 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s5',
            address='127.0.0.1:50055',
            device_id=4,
            proto_dump_file='logs/s5-p4runtime-requests.txt')
        s6 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s6",
            address='127.0.0.1:50056',
            device_id=5,
            proto_dump_file='logs/s6-p4runtime-requests.txt')
        s7 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s7',
            address='127.0.0.1:50057',
            device_id=6,
            proto_dump_file='logs/s7-p4runtime-requests.txt')
        s8 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s8',
            address='127.0.0.1:50058',
            device_id=7,
            proto_dump_file='logs/s8-p4runtime-requests.txt')
        s9 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s9",
            address='127.0.0.1:50059',
            device_id=8,
            proto_dump_file='logs/s9-p4runtime-requests.txt')
        s10 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s10',
            address='127.0.0.1:50060',
            device_id=9,
            proto_dump_file='logs/s10-p4runtime-requests.txt')
        s11 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s11',
            address='127.0.0.1:50061',
            device_id=10,
            proto_dump_file='logs/s11-p4runtime-requests.txt')
        s12 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s12",
            address='127.0.0.1:50062',
            device_id=11,
            proto_dump_file='logs/s12-p4runtime-requests.txt')
        s13 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s13',
            address='127.0.0.1:50063',
            device_id=12,
            proto_dump_file='logs/s13-p4runtime-requests.txt')
        s14 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s14',
            address='127.0.0.1:50064',
            device_id=13,
            proto_dump_file='logs/s14-p4runtime-requests.txt')
        s15 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s15",
            address='127.0.0.1:50065',
            device_id=14,
            proto_dump_file='logs/s15-p4runtime-requests.txt')
        s16 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s16',
            address='127.0.0.1:50066',
            device_id=15,
            proto_dump_file='logs/s16-p4runtime-requests.txt')
        s17 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s17',
            address='127.0.0.1:50067',
            device_id=16,
            proto_dump_file='logs/s17-p4runtime-requests.txt')
        s18 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s18",
            address='127.0.0.1:50068',
            device_id=17,
            proto_dump_file='logs/s18-p4runtime-requests.txt')
        s19 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s19',
            address='127.0.0.1:50069',
            device_id=18,
            proto_dump_file='logs/s19-p4runtime-requests.txt')
        s20 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s20',
            address='127.0.0.1:50070',
            device_id=19,
            proto_dump_file='logs/s20-p4runtime-requests.txt')
        s21 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s21",
            address='127.0.0.1:50071',
            device_id=20,
            proto_dump_file='logs/s21-p4runtime-requests.txt')
        s22 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s22',
            address='127.0.0.1:50072',
            device_id=21,
            proto_dump_file='logs/s22-p4runtime-requests.txt')
        s23 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s23',
            address='127.0.0.1:50073',
            device_id=22,
            proto_dump_file='logs/s23-p4runtime-requests.txt')
        s24 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s24',
            address='127.0.0.1:50074',
            device_id=23,
            proto_dump_file='logs/s24-p4runtime-requests.txt')


        sw_list =[]
        sw_list.append(s1)
        sw_list.append(s2)
        sw_list.append(s3)
        sw_list.append(s4)
        sw_list.append(s5)
        sw_list.append(s6)
        sw_list.append(s7)
        sw_list.append(s8)
        sw_list.append(s9)
        sw_list.append(s10)
        sw_list.append(s11)
        sw_list.append(s12)
        sw_list.append(s13)
        sw_list.append(s14)
        sw_list.append(s15)
        sw_list.append(s16)
        sw_list.append(s17)
        sw_list.append(s18)
        sw_list.append(s19)
        sw_list.append(s20)
        sw_list.append(s21)
        sw_list.append(s22)
        sw_list.append(s23)
        sw_list.append(s24)

        # 傳送 master arbitration update message 來建立，使得這個 controller 成為
        # master (required by P4Runtime before performing any other write operation)
        s1.MasterArbitrationUpdate()
        s2.MasterArbitrationUpdate()
        s3.MasterArbitrationUpdate()
        s4.MasterArbitrationUpdate()
        s5.MasterArbitrationUpdate()
        s6.MasterArbitrationUpdate()
        s7.MasterArbitrationUpdate()
        s8.MasterArbitrationUpdate()
        s9.MasterArbitrationUpdate()
        s10.MasterArbitrationUpdate()
        s11.MasterArbitrationUpdate()
        s12.MasterArbitrationUpdate()
        s13.MasterArbitrationUpdate()
        s14.MasterArbitrationUpdate()
        s15.MasterArbitrationUpdate()
        s16.MasterArbitrationUpdate()
        s17.MasterArbitrationUpdate()
        s18.MasterArbitrationUpdate()
        s19.MasterArbitrationUpdate()
        s20.MasterArbitrationUpdate()
        s21.MasterArbitrationUpdate()
        s22.MasterArbitrationUpdate()
        s23.MasterArbitrationUpdate()
        s24.MasterArbitrationUpdate()

        # 安裝目標 P4 程式到 switch 上
        s1.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s2.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s3.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        
        s4.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s5.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s6.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s7.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s8.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s9.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        
        s10.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s11.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s12.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s13.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s14.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s15.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        
        s16.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s17.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s18.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s19.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s20.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s21.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        
        s22.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s23.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)

        s24.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        
        # Sending digest entry
        SendDigestEntry(p4info_helper, sw=s1, digest_name="syn_ack_digest")
        SendDigestEntry(p4info_helper, sw=s1, digest_name="check_digest")
        SendDigestEntry(p4info_helper, sw=s1, digest_name="merge_digest")
        # SendDigestEntry(p4info_helper, sw=s1, digest_name="debug_digest")

        # 設定 forward rules
        # - forward to host
        writeHostForwardRules(p4info_helper,ingress_sw=s1,
                        dst_eth_addr="00:00:00:00:01:01",port=1,dst_ip_addr="10.0.1.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s9,
                        dst_eth_addr="00:00:00:00:09:02",port=1,dst_ip_addr="11.0.0.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s10,
                        dst_eth_addr="00:00:00:00:0a:03",port=1,dst_ip_addr="11.0.1.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s11,
                        dst_eth_addr="00:00:00:00:0b:04",port=1,dst_ip_addr="11.0.2.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s12,
                        dst_eth_addr="00:00:00:00:0c:05",port=1,dst_ip_addr="11.1.0.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s13,
                        dst_eth_addr="00:00:00:00:0d:06",port=1,dst_ip_addr="11.1.1.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s14,
                        dst_eth_addr="00:00:00:00:0e:07",port=1,dst_ip_addr="11.1.2.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s15,
                        dst_eth_addr="00:00:00:00:0f:08",port=1,dst_ip_addr="11.2.0.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s16,
                        dst_eth_addr="00:00:00:00:10:09",port=1,dst_ip_addr="11.2.1.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s17,
                        dst_eth_addr="00:00:00:00:11:0a",port=1,dst_ip_addr="11.2.2.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s18,
                        dst_eth_addr="00:00:00:00:12:0b",port=1,dst_ip_addr="12.0.0.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s19,
                        dst_eth_addr="00:00:00:00:13:0c",port=1,dst_ip_addr="12.0.1.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s20,
                        dst_eth_addr="00:00:00:00:14:0d",port=1,dst_ip_addr="12.0.2.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s21,
                        dst_eth_addr="00:00:00:00:15:0e",port=1,dst_ip_addr="12.1.0.1")
        writeHostForwardRules(p4info_helper,ingress_sw=s24,
                        dst_eth_addr="00:00:00:00:18:0f",port=1,dst_ip_addr="11.0.3.1")

        # - s1
        writeL3ForwardRules(p4info_helper,ingress_sw=s1,port=2,dst_ip_addr="11.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s1,port=2,dst_ip_addr="12.0.0.0",prefix=8)

        # - s2
        writeL3ForwardRules(p4info_helper,ingress_sw=s2,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s2,port=1,dst_ip_addr="12.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s2,port=2,dst_ip_addr="11.0.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s2,port=3,dst_ip_addr="11.1.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s2,port=4,dst_ip_addr="11.2.0.0",prefix=16)

        # - s3
        writeL3ForwardRules(p4info_helper,ingress_sw=s3,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s3,port=1,dst_ip_addr="11.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s3,port=2,dst_ip_addr="12.0.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s3,port=3,dst_ip_addr="12.1.0.0",prefix=16)

        # - s4
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=1,dst_ip_addr="12.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=1,dst_ip_addr="11.1.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=1,dst_ip_addr="11.2.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=2,dst_ip_addr="11.0.0.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=3,dst_ip_addr="11.0.1.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=4,dst_ip_addr="11.0.2.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s4,port=5,dst_ip_addr="11.0.3.0",prefix=24)

        # - s5
        writeL3ForwardRules(p4info_helper,ingress_sw=s5,port=1,dst_ip_addr="12.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s5,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s5,port=1,dst_ip_addr="11.0.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s5,port=1,dst_ip_addr="11.2.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s5,port=2,dst_ip_addr="11.1.0.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s5,port=3,dst_ip_addr="11.1.1.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s5,port=4,dst_ip_addr="11.1.2.0",prefix=24)

        # - s6
        writeL3ForwardRules(p4info_helper,ingress_sw=s6,port=1,dst_ip_addr="12.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s6,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s6,port=1,dst_ip_addr="11.0.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s6,port=1,dst_ip_addr="11.1.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s6,port=2,dst_ip_addr="11.2.0.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s6,port=3,dst_ip_addr="11.2.1.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s6,port=4,dst_ip_addr="11.2.2.0",prefix=24)

        # - s7
        writeL3ForwardRules(p4info_helper,ingress_sw=s7,port=1,dst_ip_addr="11.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s7,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s7,port=1,dst_ip_addr="12.1.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s7,port=2,dst_ip_addr="12.0.0.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s7,port=3,dst_ip_addr="12.0.1.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s7,port=4,dst_ip_addr="12.0.2.0",prefix=24)

        # - s8
        writeL3ForwardRules(p4info_helper,ingress_sw=s8,port=1,dst_ip_addr="11.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s8,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s8,port=1,dst_ip_addr="12.0.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s8,port=2,dst_ip_addr="12.1.0.0",prefix=24)

        # - s9
        writeL3ForwardRules(p4info_helper,ingress_sw=s9,port=2,dst_ip_addr="12.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s9,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s9,port=2,dst_ip_addr="11.1.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s9,port=2,dst_ip_addr="11.2.0.0",prefix=16)
        writeL3ForwardRules(p4info_helper,ingress_sw=s9,port=2,dst_ip_addr="11.0.1.0",prefix=24)
        writeL3ForwardRules(p4info_helper,ingress_sw=s9,port=2,dst_ip_addr="11.0.2.0",prefix=24)

        # - s10~s21 (only connect to server)
        writeL3ForwardRules(p4info_helper,ingress_sw=s10,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s11,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s12,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s13,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s14,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s15,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s16,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s17,port=2,dst_ip_addr="10.0.0.0",prefix=8)

        writeL3ForwardRules(p4info_helper,ingress_sw=s18,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s19,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s20,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s21,port=2,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s24,port=2,dst_ip_addr="10.0.0.0",prefix=8)

        # - s22
        writeL3ForwardRules(p4info_helper,ingress_sw=s22,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s22,port=2,dst_ip_addr="11.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s22,port=2,dst_ip_addr="12.0.0.0",prefix=8)

        # - s23
        writeL3ForwardRules(p4info_helper,ingress_sw=s23,port=1,dst_ip_addr="10.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s23,port=2,dst_ip_addr="11.0.0.0",prefix=8)
        writeL3ForwardRules(p4info_helper,ingress_sw=s23,port=3,dst_ip_addr="12.0.0.0",prefix=8)
    
        
        # 完成寫入後，我們來讀取 s1,s2 的 table entries
        readTableRules(p4info_helper, s18)

        

        max_index = 1  # next index of register (class D)
        max_index_ABC =1500 # class ABC index
        leaf_map = {
            '11.0.0':{'sw':sw_list[4-1],'port':2},
            '11.0.1':{'sw':sw_list[4-1],'port':3},
            '11.0.2':{'sw':sw_list[4-1],'port':4},
            '11.1.0':{'sw':sw_list[5-1],'port':2},
            '11.1.1':{'sw':sw_list[5-1],'port':3},
            '11.1.2':{'sw':sw_list[5-1],'port':4},
            '11.2.0':{'sw':sw_list[6-1],'port':2},
            '11.2.1':{'sw':sw_list[6-1],'port':3},
            '11.2.2':{'sw':sw_list[6-1],'port':4},
            '12.0.0':{'sw':sw_list[7-1],'port':2},
            '12.0.1':{'sw':sw_list[7-1],'port':3},
            '12.0.2':{'sw':sw_list[7-1],'port':4},
            '12.1.0':{'sw':sw_list[8-1],'port':2},
            '11.0.3':{'sw':sw_list[4-1],'port':5}
        }
        entryA = {}
        entryB = {}
        entryC = {}
        prefix_32 = {}
        danger_list = {}
        drop_list=[]
        
        # test = threading.Thread(target=testingFunc,args=(p4info_helper, s1, "Basic_ingress.ingressTunnelCounter"))
        # test.start()
        # 並於每 2 秒內打印 tunnel counters
        while True:
            digests = s1.DigestList()
            if digests.WhichOneof('update')=='digest':
                print("Received DigestList message")
                digest = digests.digest
                digest_name = p4info_helper.get_digests_name(digest.digest_id)
                print "===============================" 
                print "Digest name: ", digest_name 
                print "List ID: ", digest.digest_id
                if digest_name == "syn_ack_digest":
                    for members in digest.data:
                        #print members
                        if members.WhichOneof('data')=='struct':
                            # print byte_pbyte(members.struct.members[0].bitstring)
                            if members.struct.members[0].WhichOneof('data') == 'bitstring':
                                dst_IP = prettify(members.struct.members[0].bitstring)
                    print "get syn digest data:%s" % dst_IP
                    print "==============================="
                    print "drop_list:%s" % drop_list
                    if not (dst_IP.replace('.','+',2).split('.')[0].replace('+','.') in drop_list):
                        if not prefix_32.has_key(dst_IP) :
                            writeSynAckCountRules(p4info_helper, ingress_sw=s1,dst_ip_addr=dst_IP,prefix=32,index=max_index)
                            prefix_32[dst_IP] = max_index
                            max_index = max_index+1
                elif digest_name == "check_digest":
                    for members in digest.data:
                        #print members
                        if members.WhichOneof('data')=='struct':
                            # print byte_pbyte(members.struct.members[0].bitstring)
                            if members.struct.members[0].WhichOneof('data') == 'bitstring':
                                dst_IP = prettify(members.struct.members[0].bitstring)
                            if members.struct.members[1].WhichOneof('data') == 'bitstring':
                                index = int_prettify(members.struct.members[1].bitstring)
                    print "IP:%s" % dst_IP
                    print "index:%s" % index

                    if not(dst_IP.replace('.','+',2).split('.')[0].replace('+','.') in drop_list):
                        # delete dangerous entry
                        if prefix_32.has_key(dst_IP) :
                            # classing class D
                            del prefix_32[dst_IP]
                            if not danger_list.has_key(dst_IP.replace('.','+',2).split('.')[0].replace('+','.')):
                                danger_list[dst_IP.replace('.','+',2).split('.')[0].replace('+','.')]={}
                            danger_list[dst_IP.replace('.','+',2).split('.')[0].replace('+','.')][dst_IP.split('.')[3]] = index
                        elif entryC.has_key(dst_IP.replace('.','+',1).split('.',2)[0].replace('+','.')) :
                            # delete dangerous class C entry
                            last_dict = entryC.get(dst_IP.replace('.','+',1).split('.',2)[0].replace('+','.'))
                            if last_dict.has_key(dst_IP.split('.')[2]):
                                del last_dict[dst_IP.split('.')[2]]
                                if last_dict == {} :
                                    del entryC[dst_IP.replace('.','+',1).split('.',2)[0].replace('+','.')]
                                else :
                                    entryC[dst_IP.replace('.','+',1).split('.',2)[0].replace('+','.')] = last_dict
                                dst_ip = dst_IP.replace('.','+',2).split('.',2)[0].replace('+','.') + '.0'
                                deleteSynAckCountRules(p4info_helper, ingress_sw=s1,dst_ip_addr=dst_ip,prefix=24,index=index)
                        elif entryB.has_key(dst_IP.split('.')[0]):
                            # delete dangerous class B entry
                            last_dict = entryB.get(dst_IP.split('.')[0])
                            if last_dict.has_key(dst_IP.split('.')[1]):
                                del last_dict[dst_IP.split('.')[1]]
                                if last_dict == {}:
                                    del entryB[dst_IP.split('.')[0]]
                                else :
                                    entryB[dst_IP.split('.')[0]] = last_dict
                                dst_ip = dst_IP.replace('.','+',1).split('.')[0].replace('+','.') + '.0.0'
                                deleteSynAckCountRules(p4info_helper, ingress_sw=s1,dst_ip_addr=dst_ip,prefix=16,index=index)
                        elif dst_IP.split('.')[0] in entryA :
                            # delete dangerous class A entry
                            del entryA[dst_IP.split('.')[0]]
                            dst_ip = dst_IP.split('.')[0]+'.0.0.0'
                            deleteSynAckCountRules(p4info_helper, ingress_sw=s1,dst_ip_addr=dst_ip,prefix=8,index=index) 

                        print("=========after checking===========")
                        print("[entryD]")
                        print(prefix_32)
                        print("[danger]")
                        print(danger_list)
                        print("[entryC]")
                        print(entryC)
                        print("[entryB]")
                        print(entryB)
                        print("[entryA]")
                        print(entryA)
                
                elif digest_name=='merge_digest' :
                    print("=========before merge===========")
                    print("[entryD]")
                    print(prefix_32)
                    print("[danger]")
                    print(danger_list)
                    print("[entryC]")
                    print(entryC)
                    print("[entryB]")
                    print(entryB)
                    print("[entryA]")
                    print(entryA)
                    print("[drop]")
                    print(drop_list)
                    # drop ip in dangerous list
                    for drop_ip,pair in danger_list.items() :
                        drop_list.append(drop_ip)
                        writeDropForwardRules(p4info_helper,ingress_sw=leaf_map[drop_ip]['sw'],port=leaf_map[drop_ip]['port'])
                        for key,index in pair.items():
                            deleteSynAckCountRules(p4info_helper, ingress_sw=s1,dst_ip_addr=drop_ip+'.'+key,prefix=32,index=index)
                    danger_list.clear()
                    
                    # merge entry
                    # entryD : all add to entryC
                    for ip,index in prefix_32.items() :
                        key_entryC = ip.replace('.','+',1).split('.')[0].replace('+','.')
                        write_ip = ip.replace('.','+',2).split('.')[0].replace('+','.')+'.0'
                        if entryC.has_key(key_entryC) :
                            last_dict = entryC.get(key_entryC)
                            if not (last_dict.has_key(ip.split('.')[2])):
                                last_dict[ip.split('.')[2]] = 0
                                entryC[key_entryC] = last_dict
                        else :
                            entryC[key_entryC] = {ip.split('.')[2]:0}
                        deleteSynAckCountRules(p4info_helper,ingress_sw=s1,dst_ip_addr=ip,prefix=32, index=index)
                    prefix_32.clear()

                    # entryC : merge some entryC to entryB
                    for keyC,dictC in entryC.items() :
                        if len(dictC) >= 3 :
                            key_entryB = keyC.split('.')[0]
                            write_ip = keyC+'.0.0'
                            if entryB.has_key(key_entryB):
                                dictB = entryB[key_entryB]
                                dictB[keyC.split('.')[1]] = 0
                                entryB[key_entryB] = dictB
                            else:
                                entryB[key_entryB] = {keyC.split('.')[1]:0}
                            for key,index in dictC.items():
                                if index > 0 :
                                    deleteSynAckCountRules(p4info_helper,ingress_sw=s1,dst_ip_addr=keyC+'.'+key+'.0',prefix=24, index=index)
                            del entryC[keyC]

                    # entryB : merge some entryB to entryA
                    for keyB,dictB in entryB.items() :
                        if len(dictB) >= 3 :
                            write_ip = keyB+'.0.0.0'
                            entryA[keyB] = 0
                            for key,index in dictB.items():
                                if index>0 :
                                    deleteSynAckCountRules(p4info_helper,ingress_sw=s1,dst_ip_addr=keyB+'.'+key+'.0.0',prefix=16, index=index)
                            del entryB[keyB]
                            # writeSynAckCountRules(p4info_helper,ingress_sw=s1,dst_ip_addr=write_ip,prefix=8,index=max_index_ABC)
                    
                    # write entry 
                    for keyC,dictC in entryC.items() :
                        for key,index in dictC.items() :
                            if index==0 :
                                entryC[keyC][key]=max_index_ABC
                                writeSynAckCountRules(p4info_helper,ingress_sw=s1,dst_ip_addr=keyC+'.'+key+'.0',prefix=24,index=max_index_ABC)
                                max_index_ABC+=1
                    for keyB,dictB in entryB.items() :
                        for key,index in dictB.items() :
                            if index==0 :
                                entryB[keyB][key]=max_index_ABC
                                writeSynAckCountRules(p4info_helper,ingress_sw=s1,dst_ip_addr=keyB+'.'+key+'.0.0',prefix=16,index=max_index_ABC)
                                max_index_ABC+=1
                    for keyA,index in entryA.items() :
                        if index==0:
                                entryA[keyA]=max_index_ABC
                                writeSynAckCountRules(p4info_helper,ingress_sw=s1,dst_ip_addr=keyA+".0.0.0",prefix=8,index=max_index_ABC)
                                max_index_ABC+=1
                            

  
                    print("=========after merge===========")
                    print("[entryD]")
                    print(prefix_32)
                    print("[danger]")
                    print(danger_list)
                    print("[entryC]")
                    print(entryC)
                    print("[entryB]")
                    print(entryB)
                    print("[entryA]")
                    print(entryA)
                
                # elif digest_name=="debug_digest":
                #     for members in digest.data:
                #         #print members
                #         if members.WhichOneof('data')=='struct':
                #             # print byte_pbyte(members.struct.members[0].bitstring)
                #             if members.struct.members[0].WhichOneof('data') == 'bitstring':
                #                 index = int_prettify(members.struct.members[0].bitstring)
                #             if members.struct.members[1].WhichOneof('data') == 'bitstring':
                #                 syn = int_prettify(members.struct.members[1].bitstring)
                #             if members.struct.members[2].WhichOneof('data') == 'bitstring':
                #                 ack = int_prettify(members.struct.members[2].bitstring)
                    
                #     print "==========================="
                #     print "index:%s" % index
                #     print "syn:%s" % syn
                #     print "ack:%s" % ack
                #     print "==========================="


    except KeyboardInterrupt:
        # using ctrl + c to exit
        print "Shutting down."
    except grpc.RpcError as e:
        printGrpcError(e)

    # Then close all the connections
    ShutdownAllSwitchConnections()


if __name__ == '__main__':
    """ Simple P4 Controller
        Args:
            p4info:     指定 P4 Program 編譯產生的 p4info (PI 制定之格式、給予 controller 讀取)
            bmv2-json:  指定 P4 Program 編譯產生的 json 格式，依據 backend 不同，而有不同的檔案格式
     """

    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    # Specified result which compile from P4 program
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
            type=str, action="store", required=False,
            default="./simple.p4info")
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
            type=str, action="store", required=False,
            default="./simple.json")
    args = parser.parse_args()

    if not os.path.exists(args.p4info):
        parser.print_help()
        print "\np4info file not found: %s\nPlease compile the target P4 program first." % args.p4info
        parser.exit(1)
    if not os.path.exists(args.bmv2_json):
        parser.print_help()
        print "\nBMv2 JSON file not found: %s\nPlease compile the target P4 program first." % args.bmv2_json
        parser.exit(1)

    # Pass argument into main function
    main(args.p4info, args.bmv2_json)
