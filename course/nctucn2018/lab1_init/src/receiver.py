#!/usr/bin/env python

from random import *
from scapy.all import *
from time import *

# Set source IP address and destination interface (Task 4.)


# Store the receiving secret
id = ''
received = []


'''
Handle the received packet
'''
def packetHandler(packet):
    # Use global variable
    global id, received

    # Show the receiving packet
    packet.show()

    # Filtering packet
    if TCP in packet and packet['IP'].src == src_ip:
        if packet['TCP'].seq == 2: 
            print '[INFO] Receive packet with customized protocol'
            id = str(packet['Raw'])[-6:]
        elif packet['TCP'].seq == 3: 
            print '[INFO] Receive packet with secret payload'
            received.append(packet['Raw'])


'''
Main function
'''
def main():
    # Sniff packets on destination interface (Task 4.)
    print '[INFO] Sniff on %s' % dst_iface
    

    # Dump the sniffed packet into PCAP file (Task 4.)
    print '[INFO] Write into PCAP file'   


    # Write the receiving secret into file
    with open('./out/recv_secret.txt', 'w') as file:
        file.write('%s\n' % id)
        for line in received:
            file.write('%s' % line)
    
    # Finishing receiving in a duration
    print '[INFO] Finish receiving packets in a duration'


if __name__ == '__main__':
    main()