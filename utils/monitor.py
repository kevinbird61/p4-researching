#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import argparse, grpc, os, sys, json, time
from time import sleep
from pprint import pprint
# for plot
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np


# And then we import
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

def getCounter(p4info_helper, sw, counter_name, index):
    for response in sw.ReadCounters(p4info_helper.get_counters_id(counter_name), index):
        for entity in response.entities:
            counter = entity.counter_entry
            #print "[SW: %s][Cnt: %s][Port: %d]: %d packets (%d bytes)" % (sw.name,counter_name, index,counter.data.packet_count, counter.data.byte_count)
            return counter 

def printGrpcError(e):
    print "gRPC Error: ", e.details(),
    status_code = e.code()
    print "(%s)" % status_code.name,
    # detail about sys.exc_info - https://docs.python.org/2/library/sys.html#sys.exc_info
    traceback = sys.exc_info()[2]
    print "[%s:%s]" % (traceback.tb_frame.f_code.co_filename, traceback.tb_lineno)

def main(p4info_file_path, bmv2_file_path, cnt_config):
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    try: 
        s1 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s1',
            address='127.0.0.1:50051',
            device_id=0,
            proto_dump_file='logs/s1-p4runtime-requests.txt')
        s1.MasterArbitrationUpdate()
        # print "Size: " + str(len(cnt_config["counter"]))
        counter_list=[]
        for i in cnt_config["counter"]:
            counter_list.append({
                "name": "",
                "index": "",
                "packets": [],
                "bytes": []
            })
        timer=[]

        # figure init
        plt.figure(1)

        # 並於每 2 秒內 read counters
        tStart = time.time()
        while True:
            time_tick=0
            sleep(2)
            index = 0
            for i in cnt_config["counter"]:
                # fetch counter
                counter = getCounter(p4info_helper, s1, str(i["name"]), i["index"])
                counter_list[index]["name"] = str(i["name"])
                counter_list[index]["index"] = i["index"]
                # append 
                if len(counter_list[index]["packets"]) > 0:
                    counter_list[index]["packets"].append(counter.data.packet_count - counter_list[index]["packets"][-1])
                else: 
                    counter_list[index]["packets"].append(counter.data.packet_count)
                if len(counter_list[index]["bytes"]) > 0:
                    counter_list[index]["bytes"].append(counter.data.byte_count - counter_list[index]["bytes"][-1])
                else: 
                    counter_list[index]["bytes"].append(counter.data.byte_count)

                print counter.data.byte_count
                print counter.data.packet_count
                # inc
                index+=1
            
            tEnd = time.time()#計時結束
            timer.append(tEnd-tStart)
            
            # using matplotlib to plot 
            for i in range(len(cnt_config["counter"])):
                plt.figure(1)
                # plot position
                pos = str(len(cnt_config["counter"]))+"1"+str(i+1)
                plt.subplot(int(pos))
                plt.gca().set_title(counter_list[i]["name"]+"[Port: "+str(counter_list[i]["index"])+"]")
                plt.plot(timer, counter_list[i]["packets"])

            if tEnd-tStart > 10:
                break

        print counter_list 
        plt.show()
        

    except KeyboardInterrupt:
        # using ctrl + c to exit
        print "Shutting down."
    except grpc.RpcError as e:
        printGrpcError(e)

    # Then close all the connections
    ShutdownAllSwitchConnections()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    # Specified result which compile from P4 program
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
            type=str, action="store", required=True)
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
            type=str, action="store", required=True)
    parser.add_argument('--cnt-config', help='Counter configuration file for scenario.',
            type=str, action="store", required=True)
    args = parser.parse_args()

    if not os.path.exists(args.p4info):
        parser.print_help()
        print "\np4info file not found: %s\nPlease compile the target P4 program first." % args.p4info
        parser.exit(1)
    if not os.path.exists(args.bmv2_json):
        parser.print_help()
        print "\nBMv2 JSON file not found: %s\nPlease compile the target P4 program first." % args.bmv2_json
        parser.exit(1)

    # read data
    with open(args.cnt_config) as f:
        data = json.load(f)

    # Pass argument into main function
    main(args.p4info, args.bmv2_json, data)