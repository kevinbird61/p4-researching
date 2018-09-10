# Step 1: add network namespace 
sudo ip netns add h1
sudo ip netns add h2
sudo ip netns add h3
sudo ip netns add h4

# Step 2 (optional)
sudo ip netns exec h1 ip link set lo up
sudo ip netns exec h2 ip link set lo up

# ---------------------------------------------------------- h1 ----------------------------------------------------------
# build first link: s1-eth1 <-> h1-eth0
sudo ip link add s1-eth1 type veth peer name h1-eth0
# sudo ip link set s1-eth1 netns s1
sudo ip link set h1-eth0 netns h1

# activate with IP address assign
sudo ip netns exec h1 ip link set dev h1-eth0 up
sudo ip netns exec h1 ip link set h1-eth0 address 00:0a:00:00:01:01
sudo ip netns exec h1 ip addr add 10.0.1.1/24 dev h1-eth0
# sudo ip netns exec s1 ip link set dev s1-eth1 up
sudo ip link set dev s1-eth1 up
# sudo ip netns exec s1 ip link set s1-eth1 address 00:00:00:00:10:10
sudo ip link set s1-eth1 address 00:00:00:00:10:10
#sudo ip netns exec s1 ip addr add 10.0.1.2/24 dev s1-eth1
sudo ip addr add 10.0.1.2/24 dev s1-eth1

# ---------------------------------------------------------- h2 ----------------------------------------------------------
# build second link: s1-eth2 <-> h2-eth0
sudo ip link add s1-eth2 type veth peer name h2-eth0
# sudo ip link set s1-eth2 netns s1
sudo ip link set h2-eth0 netns h2

# activate with IP address assign
sudo ip netns exec h2 ip link set dev h2-eth0 up
sudo ip netns exec h2 ip link set h2-eth0 address 00:0a:00:00:02:02
sudo ip netns exec h2 ip addr add 10.0.2.1/24 dev h2-eth0
sudo ip link set dev s1-eth2 up
sudo ip link set s1-eth2 address 00:a0:00:00:02:02
sudo ip addr add 10.0.2.2/24 dev s1-eth2

# ---------------------------------------------------------- h3 ----------------------------------------------------------
# build link: s1-eth3 <-> h3-eth0
sudo ip link add s1-eth3 type veth peer name h3-eth0
# sudo ip link set s1-eth3 netns s1
sudo ip link set h3-eth0 netns h3

# activate with IP address assign
sudo ip netns exec h3 ip link set dev h3-eth0 up
sudo ip netns exec h3 ip link set h3-eth0 address 00:0b:00:00:02:02
sudo ip netns exec h3 ip addr add 10.0.3.1/24 dev h3-eth0
sudo ip link set dev s1-eth3 up
sudo ip link set s1-eth3 address 00:b0:00:00:02:02
sudo ip addr add 10.0.3.2/24 dev s1-eth3

# ---------------------------------------------------------- h4 ----------------------------------------------------------
# build link: s1-eth4 <-> h4-eth0
sudo ip link add s1-eth4 type veth peer name h4-eth0
# sudo ip link set s1-eth3 netns s1
sudo ip link set h4-eth0 netns h4

# activate with IP address assign
sudo ip netns exec h4 ip link set dev h4-eth0 up
sudo ip netns exec h4 ip link set h4-eth0 address 00:0c:00:00:02:02
sudo ip netns exec h4 ip addr add 10.0.4.1/24 dev h4-eth0
sudo ip link set dev s1-eth4 up
sudo ip link set s1-eth4 address 00:c0:00:00:02:02
sudo ip addr add 10.0.4.2/24 dev s1-eth4


## disable all ipv6 
sudo ip netns exec h1 sysctl net.ipv6.conf.h1-eth0.disable_ipv6=1
sudo ip netns exec h2 sysctl net.ipv6.conf.h2-eth0.disable_ipv6=1
sudo ip netns exec h3 sysctl net.ipv6.conf.h3-eth0.disable_ipv6=1
sudo ip netns exec h4 sysctl net.ipv6.conf.h4-eth0.disable_ipv6=1
sudo sysctl net.ipv6.conf.s1-eth1.disable_ipv6=1
sudo sysctl net.ipv6.conf.s1-eth2.disable_ipv6=1
sudo sysctl net.ipv6.conf.s1-eth3.disable_ipv6=1
sudo sysctl net.ipv6.conf.s1-eth4.disable_ipv6=1

## setting routing table
sudo ip netns exec h1 ip route add default via 10.0.1.2
sudo ip netns exec h2 ip route add default via 10.0.2.2
sudo ip netns exec h3 ip route add default via 10.0.3.2
sudo ip netns exec h4 ip route add default via 10.0.4.2