#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import argparse, grpc, os, sys
from time import sleep

# set our lib path
"""
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
        '../../utils/'))
"""
# And then we import
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

def writeForwardRules(p4info_helper,ingress_sw,
    dst_eth_addr,port,dst_ip_addr):
    """
        Install rules:
        
        做到原本 sx-runtime.json 的工作
            p4info_helper:  the P4Info helper
            ingress_sw:     the ingress switch connection
            dst_eth_addr:   the destination IP to match in the ingress rule
            port:           port of switch 
            dst_ip_addr:    the destination Ethernet address to write in the egress rule
    """

    # 1. Ingress rule
    table_entry = p4info_helper.buildTableEntry(
        table_name="basic_tutorial_ingress.ipv4_forwarding.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,32)
        },
        action_name="basic_tutorial_ingress.ipv4_forwarding.ipv4_forward",
        action_params={
            "dstAddr": dst_eth_addr,
            "port": port
        })
    # write into ingress of target sw
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed ingress tunnel rule on %s" % ingress_sw.name


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

def printGrpcError(e):
    print "gRPC Error: ", e.details(),
    status_code = e.code()
    print "(%s)" % status_code.name,
    # detail about sys.exc_info - https://docs.python.org/2/library/sys.html#sys.exc_info
    traceback = sys.exc_info()[2]
    print "[%s:%s]" % (traceback.tb_frame.f_code.co_filename, traceback.tb_lineno)

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
        # for s3
        s3 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name="s3",
            address='127.0.0.1:50053',
            device_id=2,
            proto_dump_file='logs/s3-p4runtime-requests.txt')

        # 傳送 master arbitration update message 來建立，使得這個 controller 成為
        # master (required by P4Runtime before performing any other write operation)
        s1.MasterArbitrationUpdate()
        s2.MasterArbitrationUpdate()
        s3.MasterArbitrationUpdate()

        # 安裝目標 P4 程式到 switch 上
        s1.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        print "Installed P4 Program using SetForardingPipelineConfig on s1"

        s2.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        print "Installed P4 Program using SetForardingPipelineConfig on s2"

        s3.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        print "Installed P4 Program using SetForardingPipelineConfig on s3"

        # 設定 default action = drop (via P4 program)
        
        # 設定 forward rules
        # - s1
        writeForwardRules(p4info_helper,ingress_sw=s1,
                        dst_eth_addr="00:00:00:00:01:01",port=1,dst_ip_addr="10.0.1.1")
        writeForwardRules(p4info_helper,ingress_sw=s1,
                        dst_eth_addr="00:00:00:02:02:00",port=2,dst_ip_addr="10.0.2.2")
        writeForwardRules(p4info_helper,ingress_sw=s1,
                        dst_eth_addr="00:00:00:03:03:00",port=3,dst_ip_addr="10.0.3.3")
        # - s2
        writeForwardRules(p4info_helper,ingress_sw=s2,
                        dst_eth_addr="00:00:00:01:02:00",port=2,dst_ip_addr="10.0.1.1")
        writeForwardRules(p4info_helper,ingress_sw=s2,
                        dst_eth_addr="00:00:00:00:02:02",port=1,dst_ip_addr="10.0.2.2")
        writeForwardRules(p4info_helper,ingress_sw=s2,
                        dst_eth_addr="00:00:00:03:03:00",port=3,dst_ip_addr="10.0.3.3")
        # - s1
        writeForwardRules(p4info_helper,ingress_sw=s3,
                        dst_eth_addr="00:00:00:01:03:00",port=2,dst_ip_addr="10.0.1.1")
        writeForwardRules(p4info_helper,ingress_sw=s3,
                        dst_eth_addr="00:00:00:02:03:00",port=3,dst_ip_addr="10.0.2.2")
        writeForwardRules(p4info_helper,ingress_sw=s3,
                        dst_eth_addr="00:00:00:00:03:03",port=1,dst_ip_addr="10.0.3.3")

        # 完成寫入後，我們來讀取 s1,s2 的 table entries
        readTableRules(p4info_helper, s1)
        readTableRules(p4info_helper, s2)
        readTableRules(p4info_helper, s3)


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