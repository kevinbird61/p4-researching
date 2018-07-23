FROM ubuntu

# install deps
RUN apt update -y && apt install --no-install-recommends -y -q net-tools iputils-ping git vim curl wget openssh-server sudo

# Install P4-related deps
RUN KERNEL=$(uname -r) && \ 
    apt install -y --no-install-recommends \
    autoconf automake \
    build-essential \
    ca-certificates cmake cpp curl \
    flex \
    git \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libc6-dev \
    libevent-dev \
    libffi-dev \
    libfl-dev \
    libgc-dev \
    libgc1c2 \
    libgflags-dev \
    libgmp-dev \
    libgmp10 \
    libgmpxx4ldbl \
    libjudy-dev \
    libpcap-dev \
    libreadline-dev \
    libssl-dev \
    libtool \
    linux-headers-$KERNEL\
    make \
    pkg-config python python-dev python-ipaddr python-pip python-scapy python-setuptools \
    tcpdump \
    unzip \
    vim \
    wget \ 
    xcscope-el \
    xterm \
    && \
    sudo -H pip install cffi grpcio scapy ipaddr psutil

# Install P4 dev packages (v1)
RUN cd && \
    wget https://github.com/TakeshiTseng/ONOS-P4-Tools-Deb/releases/download/1.0.1/p4tools-deb.tar.gz && \
    tar zxvf p4tools-deb.tar.gz && \
    cd p4tools-deb/ && \
    sudo dpkg -i grpc.deb protobuf.deb p4runtime.deb thrift-0.9.2.deb bmv2.deb p4c.deb && \
    sudo ldconfig

# Mininet 
RUN apt update && apt upgrade && apt install mininet
