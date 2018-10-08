#!/usr/bin/env python

from scapy.all import *

'''
Define your own protocol
'''
class Protocol(Packet):
    # Set the name of protcol (Task 2.)
    name = ''

    # Define the fields in protocol (Task 2.)
    fields_desc = [ 
        
    ]

'''
Add customized protocol into IP layer
'''
bind_layers(TCP, Protocol, frag = 0, proto = 99)
conf.stats_classic_protocols += [Protocol]
conf.stats_dot11_protocols += [Protocol]