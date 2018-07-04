#!/usr/bin/env python
import argparse, sys, socket, random, struct

from scapy.all import sendp, send, get_if_list, get_if_list, get_if_hwaddr, hexdump
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP 

def get_if():
    iface=None 
    for i in get_if_list():
        # find hx-eth0
        if "eth0" in i:
            iface=i;
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ip', type=str, help="The destination IP address.")
    parser.add_argument('--msg', type=str, help="The message which will send to dst.")

    args = parser.parse_args()

    addr = socket.gethostbyname(args.ip)
    iface = get_if()

    # start to pack
    print "sending on interface {} to IP addr {}".format(iface, str(addr))
    pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    pkt = pkt / IP(dst=addr) / TCP(dport=1234, sport=random.randint(49152,65535)) / args.msg

    pkt.show2()

    # send 
    sendp(pkt, iface=iface, verbose=False)

if __name__ == '__main__':
    main()