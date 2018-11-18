#!/usr/bin/env python
import argparse, sys, socket, random, struct, time

from scapy.all import sendp, send, get_if_list, get_if_list, get_if_hwaddr, hexdump
from scapy.all import Packet
from scapy.all import Ether, IP, IPv6, UDP, TCP 

sip_port=5060

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
    parser.add_argument('-v', type=str, help="Specify using (4)IPv4/(6)IPv6.")
    parser.add_argument('--ip', type=str, help="The destination IP address.")
    parser.add_argument('--loop', type=int, help="Number of loop.", default=0)
    parser.add_argument('--msg', type=str, help="The message which will send to dst.",default="Hello World")
    parser.add_argument('--dport', type=int, help="TCP/UDP source port.", default=1234)
    parser.add_argument('--sport', type=int, help="TCP/UDP destination port.", default=random.randint(49152,65535))


    args = parser.parse_args()

    addr = socket.gethostbyname(args.ip)
    iface = get_if()

    # start to pack
    if args.v is "4":
        print "sending on interface {} to IP addr {}".format(iface, str(addr))
        for x in range(0, args.loop):
            pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
            pkt = pkt / IP(dst=addr) / TCP(dport=args.dport, sport=args.sport) / args.msg
            # show
            pkt.show2()
            # send 
            sendp(pkt, iface=iface, verbose=False)
            # sleep 
            time.sleep(1)
    elif args.v is "6":
        print "sending on interface {} to IPv6 addr {}".format(iface, str(addr))
        for x in range(0, args.loop):
            pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
            pkt = pkt / IPv6(dst=addr) / TCP(dport=args.dport, sport=args.sport) / args.msg
            # show
            pkt.show2()
            # send 
            sendp(pkt, iface=iface, verbose=False)

if __name__ == '__main__':
    main()
