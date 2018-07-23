#!/usr/bin/env python
import argparse, sys, socket, random, struct

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
    parser.add_argument('--msg', type=str, help="The message which will send to dst.",default="Hello World")
	parser.add_argument('--sip_callee', type=str, help="[SIP] Callee Name.", default="bob")
	parser.add_argument('--sip_caller', type=str, help="[SIP] Caller Name", default="kevin")
	parser.add_argument('--sip_callid', type=str, help="[SIP] CallID", default="1234567891")

    args = parser.parse_args()

    addr = socket.gethostbyname(args.ip)
    iface = get_if()

    # start to pack
    if args.v is "4":
        print "sending on interface {} to IP addr {}".format(iface, str(addr))
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
        pkt = pkt / IP(dst=addr) / TCP(dport=1234, sport=random.randint(49152,65535)) / args.msg
        # show
        pkt.show2()
        # send 
        sendp(pkt, iface=iface, verbose=False)
    elif args.v is "6":
        print "sending on interface {} to IPv6 addr {}".format(iface, str(addr))
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
        pkt = pkt / IPv6(dst=addr) / TCP(dport=1234, sport=random.randint(49152,65535)) / args.msg
        # show
        pkt.show2()
        # send 
        sendp(pkt, iface=iface, verbose=False)
	elif args.v is "sip-reg":
		# SIP Register
		# Reference: https://github.com/unregistered436/scapy/blob/master/sipAttack.py
		print "sending on interface {} to IPv4 addr {}".format(iface, str(addr))
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
        pkt = pkt / IP(dst=addr) / UDP(dport=sip_port, sport=sip_port)) 
		# Create SIP Payload
		# FIXME:
		sip = ("REGISTER sip:{} SIP/2.0\r\n".format(str(addr))
				"To: <sip:{}@{}:{}>\r\n".format(args.sip_callee, str(addr), str(port))
				"Via: SIP/2.0/UDP {}:{}\r\n".format(args.sip_caller, str(port))
				"From: <sip:{}@{}:{}>\r\n".format(args.sip_callee, args.sip_caller, str(port))
				"Call-ID: {}@{}\r\n".format(args.sip_callid, args.sip_caller)
				"CSeq: 1 INVITE\r\n"
				"User-agent: Flooder_script\r\n"
				"Max-Forwards: 5\r\n"
				"Content-Length: 0\r\n\r\n")
		pkt = pkt / sip
        # show
        pkt.show2()
        # send 
        sendp(pkt, iface=iface, verbose=False)
	elif args.v is "sip-invite":
		# SIP INVITE
		# Reference: https://github.com/unregistered436/scapy/blob/master/sipAttack.py
		print "sending on interface {} to IPv4 addr {}".format(iface, str(addr))
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
        pkt = pkt / IP(dst=addr) / UDP(dport=sip_port, sport=sip_port)) 
		# Create SIP Payload
		# FIXME: From
		sip = ("INVITE sip:{}@{} SIP/2.0\r\n".format(args.sip_callee,str(addr))
				"To: <sip:{}@{}:{}>\r\n".format(args.sip_callee, str(addr), str(port))
				"Via: SIP/2.0/UDP {}:{}\r\n".format(args.sip_caller, str(port))
				"From: <sip:{}@{}:{}>\r\n".format(args.sip_caller, args.sip_caller, str(port))
				"Call-ID: {}@{}\r\n".format(args.sip_callid, args.sip_caller)
				"CSeq: 1 INVITE\r\n"
				"User-agent: Flooder_script\r\n"
				"Max-Forwards: 5\r\n"
				"Content-Length: 0\r\n\r\n")
		pkt = pkt / sip
        # show
        pkt.show2()
        # send 
        sendp(pkt, iface=iface, verbose=False)
		

if __name__ == '__main__':
    main()
