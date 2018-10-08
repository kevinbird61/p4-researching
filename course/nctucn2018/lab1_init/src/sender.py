#!/usr/bin/env python

import argparse
from scapy.all import *

# Import protocol
from Protocol import Protocol

# Set source and destination IP address (Task 3.)


# Set source and destination port (Task 3.)



'''
Main function
'''
def main():
    # Define IP header (Task 3.)
    ip = IP()

    # Define customized header (Task 3.)
    my_id = ''
    my_dept = ''
    my_gender = ''
    student = Protocol(id = my_id, dept = dept, gender = my_gender)

    # Read file and store into list
    count = 0
    secret = []
    tmp = ''.join(reversed(my_id))
    with open('./data/secret.txt', 'r') as file:
        for line in file:
            line = tmp[count % 7] + line
            secret.append(line)
            count += 1

    # Send packets
    for i in range(0, len(secret)):
        # TCP connection - SYN / SYN-ACK
        tcp_syn = TCP(sport = src_port, dport = dst_port, flags = 'S', seq = 0)
        packet = ip / tcp_syn
        tcp_syn_ack = sr1(packet)
        print '[INFO] Send SYN and receive SYN-ACK'
        tcp_syn_ack.show()

        # TCP connection - ACK (Task 3.)
        print '[INFO] Send ACK'

        # Send packet with customized header (Task 3.)
        print '[INFO] Send packet with customized header'

        # Send packet with secret payload (Task 3.)
        print '[INFO] Send packet with secret payload'

        
if __name__ == '__main__':
    main()