from mininet.topo import Topo
from mininet.link import TCLink

class Topology(Topo):
    def __init__(self):
        # Initialize topology
        Topo.__init__(self)

        # Add hosts into topology
        h1 = self.addHost('h1')
        h2 = self.addHost('h2')

        # Add switches into topology
        s1 = self.addSwitch('s1')
        s2 = self.addSwitch('s2')
        s3 = self.addSwitch('s3')

        # Add links into topology
        self.addLink(s1, h1, port1=1, port2=1)
        self.addLink(s3, h2, port1=1, port2=1)
        self.addLink(s1, s3, port1=3, port2=2)
        self.addLink(s1, s2, port1=2, port2=1)
        self.addLink(s3, s2, port1=3, port2=2)
      

topos = {
    'topo': (lambda: Topology())
}