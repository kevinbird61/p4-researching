#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import argparse, grpc, os, sys
from time import sleep
from scapy.all import *

# set our lib path
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
        '../../../utils/'))

SWITCH_TO_HOST_PORT = 1
SWITCH_TO_SWITCH_PORT = 2

# And then we import
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

def writeARPReply(p4info_helper, sw, in_port, dst_eth_addr, port=None):
    table_entry = p4info_helper.buildTableEntry(
        table_name = "basic_tutorial_ingress.arp.arp_exact",
        match_fields = {
            "standard_metadata.ingress_port": in_port,
            "hdr.ethernet.dstAddr": dst_eth_addr
        },
        action_name = "basic_tutorial_ingress.arp.arp_reply",
        action_params = {
            "port": port
        })
    sw.WriteTableEntry(table_entry)
    print "Installed ARP Reply rule via P4Runtime."

def writeARPFlood(p4info_helper, sw, in_port, dst_eth_addr, port=None):
    table_entry = p4info_helper.buildTableEntry(
        table_name = "basic_tutorial_ingress.arp.arp_exact",
        match_fields = {
            "standard_metadata.ingress_port": in_port,
            "hdr.ethernet.dstAddr": dst_eth_addr
        },
        action_name = "basic_tutorial_ingress.arp.flooding",
        action_params = {
        }
    )
    sw.WriteTableEntry(table_entry)
    print "Installed ARP Flooding rule via P4Runtime."

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
    port_map = {}
    arp_rules = {}
    flag = 0
    bcast = "ff:ff:ff:ff:ff:ff"

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

        # 傳送 master arbitration update message 來建立，使得這個 controller 成為
        # master (required by P4Runtime before performing any other write operation)
        s1.MasterArbitrationUpdate()

        # 安裝目標 P4 程式到 switch 上
        s1.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        print "Installed P4 Program using SetForardingPipelineConfig on s1"

        mc_group_entry = p4info_helper.buildMCEntry(
            mc_group_id = 1,
            replicas = {
                1:1,
                2:2,
                3:3
            })
        s1.WritePRE(mc_group = mc_group_entry)
        print "Installed mgrp on s1."
        

        while True:
            packetin = s1.PacketIn()
            if packetin.WhichOneof('update')=='packet':
                # print("Received Packet-in\n")
                packet = packetin.packet.payload
                pkt = Ether(_pkt=packet)
                metadata = packetin.packet.metadata 
                for meta in metadata:
                    metadata_id = meta.metadata_id 
                    value = meta.value 

                pkt_eth_src = pkt.getlayer(Ether).src 
                pkt_eth_dst = pkt.getlayer(Ether).dst 
                ether_type = pkt.getlayer(Ether).type 

                if ether_type == 2048 or ether_type == 2054:
                    port_map.setdefault(pkt_eth_src, value)
                    arp_rules.setdefault(value, [])

                    if pkt_eth_dst == bcast:
                        if bcast not in arp_rules:
                            writeARPFlood(p4info_helper, sw=s1, in_port=value, dst_eth_addr=bcast)
                            arp_rules[value].append(bcast)
                        # build packetout
                        packetout = p4info_helper.buildPacketOut(
                            payload = packet,
                            metadata = {
                                1: "\000\000",
                                2: "\000\001"
                            }
                        )
                        s1.PacketOut(packetout)
                    else:
                        if pkt_eth_dst not in arp_rules[value]:
                            writeARPReply(p4info_helper, sw=s1, in_port=value, dst_eth_addr=pkt_eth_dst, port=port_map[pkt_eth_dst])
                            arp_rules[value].append(pkt_eth_dst)
                        if pkt_eth_src not in arp_rules[port_map[pkt_eth_dst]]:
                            writeARPReply(p4info_helper, sw=s1, in_port=port_map[pkt_eth_dst], dst_eth_addr=pkt_eth_src, port=port_map[pkt_eth_src])
                            arp_rules[port_map[pkt_eth_dst]].append(pkt_eth_src)
                        
                        packet_out = p4info_helper.buildPacketOut(
                            payload = packet,
                            metadata = {
                                1: port_map[pkt_eth_dst],
                                2: "\000\000"
                            }
                        )
                        s1.PacketOut(packet_out)
                    print "Finished PacketOut."
                    print "========================="
                    print "port_map:%s" % port_map
                    print "arp_rules:%s" % arp_rules
                    print "=========================\n"

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