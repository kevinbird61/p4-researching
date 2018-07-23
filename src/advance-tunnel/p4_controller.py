#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import argparse, grpc, os, sys
from time import sleep

# set our lib path
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
        '../../utils/'))
# And then we import
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

SWITCH_TO_HOST_PORT = 1
SWITCH_TO_SWITCH_PORT = 2

def writeTunnelRules(
    p4info_helper,
    ingress_sw,egress_sw,
    tunnel_id,
    dst_eth_addr, dst_ip_addr):
    """
        Install 3 rules:

        1. An tunnel ingress rules on the ingress switch in the ipv4_lpm table,
            that encapsulates traffic into a tunnel with the specified ID

        2. A transit rule on the ingress switch that forwards traffic based on
            the specified ID

        3. An tunnel egress rule on the egress switch that decapsulates traffic
            with the specified ID and sends it to the host

        Args:
            p4info_helper:  the P4Info helper
            ingress_sw:     the ingress switch connection
            egress_sw:      the egress switch connection
            tunnel_id:      the specified tunnel ID
            dst_eth_addr:   the destination IP to match in the ingress rule
            dst_ip_addr:    the destination Ethernet address to write in the egress rule
    """

    # 1. Tunnel Ingress rule
    table_entry = p4info_helper.buildTableEntry(
        table_name="Tunnel_ingress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr,32)
        },
        action_name="Tunnel_ingress.tunnel_ingress",
        action_params={
            "dst_id": tunnel_id
        })
    # write into ingress of target sw
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed ingress tunnel rule on %s" % ingress_sw.name

    # 2. Tunnel Transit Rule
    # build the transit rule, and then install on the ingress sw
    table_entry = p4info_helper.buildTableEntry(
        table_name="Tunnel_ingress.tunnel_exact",
        match_fields={
            "hdr.tunnel.dst_id": tunnel_id
        },
        action_name="Tunnel_ingress.tunnel_forward",
        action_params={
            "port": SWITCH_TO_SWITCH_PORT
        })
    # write into ingress of target sw
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed transit tunnel rule on %s" % ingress_sw.name

    # 3. Tunnel Egress rule
    # 在該範例演示當中，所有的 host 都會位於 port 1 上
    # （一般來說，我們需要去追蹤哪些 port 被 host 所連接！）
    table_entry = p4info_helper.buildTableEntry(
        table_name="Tunnel_ingress.tunnel_exact",
        match_fields={
            "hdr.tunnel.dst_id": tunnel_id
        },
        action_name="Tunnel_ingress.tunnel_egress",
        action_params={
            "dstAddr": dst_eth_addr,
            "port": SWITCH_TO_HOST_PORT
        })
    # write into egress of target sw
    egress_sw.WriteTableEntry(table_entry)
    print "Installed egress tunnel rule on %s" % egress_sw.name


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
            print "%s %s %d: %d packets (%d bytes)" % (
                sw.name,
                counter_name, index,
                counter.data.packet_count, counter.data.byte_count
            )

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

        # Write the rules that tunnel traffic from h1 to h2
        writeTunnelRules(p4info_helper, ingress_sw=s1, egress_sw=s2, tunnel_id=100,
                         dst_eth_addr="00:00:00:00:02:02", dst_ip_addr="10.0.2.2")

        # Write the rules that tunnel traffic from h2 to h1
        writeTunnelRules(p4info_helper, ingress_sw=s2, egress_sw=s1, tunnel_id=200,
                         dst_eth_addr="00:00:00:00:01:01", dst_ip_addr="10.0.1.1")

        # 完成寫入後，我們來讀取 s1,s2 的 table entries
        readTableRules(p4info_helper, s1)
        readTableRules(p4info_helper, s2)
        readTableRules(p4info_helper, s3)

        # 並於每 2 秒內打印 tunnel counters
        while True:
            sleep(2)
            print '\n============ Reading tunnel counters =============='
            # 最後一個參數為 tunnel ID ! (e.g. Index)
            printCounter(p4info_helper, s1, "Tunnel_ingress.ingressTunnelCounter", 100)
            printCounter(p4info_helper, s2, "Tunnel_ingress.egressTunnelCounter", 100)
            printCounter(p4info_helper, s2, "Tunnel_ingress.ingressTunnelCounter", 200)
            printCounter(p4info_helper, s1, "Tunnel_ingress.egressTunnelCounter", 200)

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
            p4info:     指定 P4 Program 編譯產生的 p4info ( PI 制定之格式、給予 controller 讀取 )
            bmv2-json:  指定 P4 Program 編譯產生的 json 格式，依據 backend 不同，而有不同的檔案格式
    """

    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    # Specified result which compile from P4 program
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
            type=str, action="store", required=False,
            default="./advance_tunnel.p4info")
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
            type=str, action="store", required=False,
            default="./advance_tunnel.json")
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

