#!/bin/bash -e

function net {
    # Create network namespaces
    addns
    # Bring up the lookup interface in the namespaces
    lookup
    # Build the link between two interface
    addlink
    # Activate the interface and assgin IP address
    activate
    # Diable all IPv6 on two interfaces
    disableIPv6
    # Set the gateway to 10.0.1.0 in the routing table
    route
}

function addns {
    echo "[INFO] Create h1 and h2 network namespaces"
    ip netns add h1
    # Create h2 network namespaces (Task 1.)

}

function delns {
    echo "[INFO] Delete h1 and h2 network namespaces"
    ip netns del h1
    # Delete h2 network namespaces (Task 1.)

}

function lookup {
    echo "[INFO] Bring up the lookup interface in h1 and h2"
    ip netns exec h1 ip link set lo up
    # Bring up the lookup interface in h2 (Task 1.)
    
}

function addlink {
    echo "[INFO] Build the link: h1-eth0 <-> h2-eth0"
    ip link add h1-eth0 type veth peer name h2-eth0
    ip link set h1-eth0 netns h1
    # Set the interface of h2 to h2-eth0 (Task 1.)
    
}

function dellink {
    echo "[INFO] Delete the link: h1-eth0 <-> h2-eth0"
    ip link delete h1-eth0 
    # Delete the interface of h2-eth0 (Task 1.)
    
}

function activate {
    echo "[INFO] Activate h1-eth0 and assign IP address"
    ip netns exec h1 ip link set dev h1-eth0 up
    ip netns exec h1 ip link set h1-eth0 address 00:0a:00:00:01:01
    ip netns exec h1 ip addr add 10.0.1.1/24 dev h1-eth0

    echo "[INFO] Activate h2-eth0 and assign IP address"
    # Activate h2-eth0 and assign IP address (Task 1.)

}

function disableIPv6 {
    echo "[INFO] Disable all IPv6 on h1-eth0 and h2-eth0"
    ip netns exec h1 sysctl net.ipv6.conf.h1-eth0.disable_ipv6=1
    # Disable all IPv6 on h2-eth0 (Task 1.)
    
}

function route {
    echo "[INFO] Set the gateway to 10.0.1.254 in routing table"
    ip netns exec h1 ip route add default via 10.0.1.254
    # Set the gateway of h2 to 10.0.1.254 (Task 1.)
    
}

function run {
    # $1: the name of namespace
    if [ $# -lt 1 ]; then
        echo "[ERROR] The format of command is WRONG"
        echo "[INFO] ./main.sh run <NAMESPACE>"
        exit
    fi

    echo "[INFO] Switch into namespace: $1"
    ip netns exec $1 /bin/bash --rcfile <(echo "PS1=\"$1> \"")
}

function upload {
    # $1: the port of container named cn2018_c
    if [ $# -lt 1 ]; then
        echo "[ERROR] The format of command is WRONG"
        echo "[INFO] ./main.sh upload <PORT>"
        exit
    fi

    echo "[INFO] Upload all files to the container"
    scp -r -P $1 ../../* root@0.0.0.0:~/
}

function download {
    # $1: the name of container
    # $2: the target path on local machine
    if [ $# -lt 2 ]; then
        echo "[ERROR] The format of command is WRONG"
        echo "[INFO] ./main.sh download <CONTAINER> <DST_PATH>"
        exit
    fi

    echo "[INFO] Download all output files"
    docker cp $1:/root/src/out/* ../out/
}

# Main
# $#: the number of parameters (receive at runtime)
# $1: the first command line argument passed

if [ $# -eq 0 ]; then
    echo "[INFO] Usage: $(basename $0) {net|run|upload|download}"
    exit
fi

if [ "$1" == "net" ]; then
    $1
    exit
elif [ "$1" == "run" ]; then
    $1 $2
    exit
elif [ "$1" == "upload" ]; then
    $1 $2
    exit
elif [ "$1" == "download" ]; then
    $1 $2 $3
    exit
fi

$1