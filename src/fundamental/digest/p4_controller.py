#!/usr/bin/env python3
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

def SendDigestEntry(p4info_helper, sw, digest_name=None):
    digest_entry = p4info_helper.buildDigestEntry(digest_name=digest_name)
    sw.WriteDigestEntry(digest_entry)
    print "Sent DigestEntry via P4Runtime."

def byte_pbyte(data):
    # check if there are multiple bytes
    if len(str(data)) > 1:
        # make list all bytes given
        msg = list(data)
        # mark which item is being converted
        s = 0
        for u in msg:
            # convert byte to ascii, then encode ascii to get byte number
            u = str(u).encode("hex")
            # make byte printable by canceling \x
            u = "\\x"+u
            # apply coverted byte to byte list
            msg[s] = u
            s = s + 1
        msg = "".join(msg)
    else:
        msg = data
        # convert byte to ascii, then encode ascii to get byte number
        msg = str(msg).encode("hex")
        # make byte printable by canceling \x
        msg = "\\x"+msg
    # return printable byte
    return msg

def prettify(mac_string):
    return ':'.join('%02x' % ord(b) for b in mac_string)

def main(p4info_file_path, bmv2_file_path):
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    try:
        s1 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s1',
            address='127.0.0.1:50051',
            device_id=0,
            proto_dump_file="logs/s1-runtime-requests.txt")

        s1.MasterArbitrationUpdate()

        s1.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
        print "Installed P4 Program using SetForardingPipelineConfig on s1"

        # Send digest entry
        SendDigestEntry(p4info_helper, sw=s1, digest_name="mac_learn_digest_t")

        # construct multicast group 
        mc_group_entry = p4info_helper.buildMCEntry(
            mc_group_id = 1,
            replicas = {
                1:1,
                2:2,
                3:3
            }
        )
        s1.WritePRE(mc_group = mc_group_entry)
        print "Installed mgrp on s1."

        port_map = {}
        arp_rules = {}
        flag = 0
        bcast = "ff:ff:ff:ff:ff:ff"

        # Using stream channel to receive DigestList
        while True: 
            digests = s1.DigestList()
            if digests.WhichOneof('update')=='digest':
                print("Received DigestList message")
                """
                    Digest format:
                    * uint32 digest_id 
                    * uint64 list_id 
                    * repeated P4Data data 
                    * int64 timestamp 
                """
                digest = digests.digest
                print "===============================" 
                print "Digest ID: ", digest.digest_id 
                print "List ID: ", digest.digest_id
                # print "[Raw]Digest msg: ", digest.data 
                digest_message_list = digest.data   
                for members in digest_message_list:
                    #print members
                    if members.WhichOneof('data')=='struct':
                        # print byte_pbyte(members.struct.members[0].bitstring)
                        if members.struct.members[0].WhichOneof('data') == 'bitstring':
                            eth_src_addr = prettify(members.struct.members[0].bitstring)
                        if members.struct.members[1].WhichOneof('data') == 'bitstring':
                            eth_dst_addr = prettify(members.struct.members[1].bitstring)
                        if members.struct.members[2].WhichOneof('data') == 'bitstring':
                            eth_type = int(members.struct.members[2].bitstring.encode('hex'),16)
                        if members.struct.members[3].WhichOneof('data') == 'bitstring':
                            port_id = members.struct.members[3].bitstring

                if eth_type == 2048 or eth_type == 2054: 
                    # learn arp 
                    port_map.setdefault(eth_src_addr, port_id)
                    arp_rules.setdefault(port_id, [])

                    if eth_dst_addr == bcast:
                        if bcast not in arp_rules:
                            writeARPFlood(p4info_helper, sw=s1, in_port=port_id, dst_eth_addr=bcast)
                            arp_rules[port_id].append(bcast)
                    else:
                        if eth_dst_addr not in arp_rules[port_id]:
                            writeARPReply(p4info_helper, sw=s1, in_port=port_id, dst_eth_addr=eth_dst_addr, port=port_map[eth_dst_addr])
                            arp_rules[port_id].append(eth_dst_addr)
                        if eth_src_addr not in arp_rules[port_map[eth_dst_addr]]:
                            writeARPReply(p4info_helper, sw=s1, in_port=port_map[eth_dst_addr], dst_eth_addr=eth_src_addr, port=port_map[eth_src_addr])
                            arp_rules[port_map[eth_dst_addr]].append(eth_src_addr)

                print "port_map:%s" % port_map
                print "arp_rules:%s" % arp_rules
                print "TS: ", digest.timestamp  
                print "==============================="

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