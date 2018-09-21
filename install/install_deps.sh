#!/bin/bash
KERNEL=$(uname -r)
sudo apt-get install -y --no-install-recommends \
  autoconf \
  automake \
  bison \
  build-essential \
  ca-certificates \
  cmake \
  cpp \
  curl \
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
  pkg-config \
  python \
  python-dev \
  python-ipaddr \
  python-pip \
  python-scapy \
  python-setuptools \
  tcpdump tmux \
  unzip \
  vim \
  wget \
  xcscope-el \
  xterm