#!/usr/bin/python

from mininet.topo import Topo
from mininet.net  import Mininet
from mininet.util import dumpNodeConnections
from mininet.log  import setLogLevel
from mininet.cli  import CLI

# build single switch topo
class SingleSwitchTopo(Topo):
    "Single switch connected to n host"
    def build(self, n=2):
        switch = self.addSwitch('s1')
        # Python's range(N) generates 0~N-1
        for h in range(n):
            host = self.addHost('h%s' % (h+1))
            self.addLink(host, switch)

# build single switch topo, with no link (need controller effort)
class NoLinkTopo(Topo):
    "Multiple switches and n hosts with no connection."
    def build(self, n=2):
        s1 = self.addSwitch('s1')
        s2 = self.addSwitch('s2')
        # s1
        for h in range(n):
            host = self.addHost('h1%s' % (h+1))
            self.addLink(host,s1)
        # s2
        for h in range(n):
            host = self.addHost('h2%s' % (h+1))
            self.addLink(host,s2)
        self.addLink(s1,s2)

# build entire network topo
def BuildTopo():
    "Create our experimental network topp."
    topo = SingleSwitchTopo(n=6)
    net = Mininet(topo)
    net.start()
    # enter into mininet cli
    CLI(net)
    print "Close the CLI."
    net.stop()

# self-defined command list
def mycmd(self,line):
    "Mininet command extension for CLI."
    # assign new topo
    net = self.mn
    # output('mycmd invoked for',net,'with line',line,'\n')

# self-define cmd under CLI
CLI.do_mycmd = mycmd

# export
topos = { 'simpletopo': SingleSwitchTopo , 'nolinktopo': NoLinkTopo }

if __name__ == '__main__':
    # start cli
    BuildTopo()
