#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import argparse, grpc, os, sys
from time import sleep
from scapy.all import *

# set our lib path
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
        '../../../utils/'))

# And then we import
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

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

        # Using stream channel to receive DigestList
        while True: 


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