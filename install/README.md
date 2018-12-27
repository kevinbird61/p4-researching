# Installation scripts

提供 P4 安裝腳本（可使用於 docker 環境的建立、或是直接安裝於 16.04.05 的主機上）

* Also provide **component** installation, e.g. grpc, pb, p4c, pi, bmv2, mininet ...
* You can use the scripts here to directly install in your local environment, e.g. VM, docker image, or physical machine.

## Install 

* All in One
   * `./install_deps.sh && ./install_p4env_v1.sh` 
* Or for individual components
   * `./install_deps.sh` 
   * And find the module you need under `component/`, with install order:
      1. `mininet.sh` 
      2. `pb.sh`
      3. `grpc.sh`
      4. `pi_and_bmv2.sh`
      5. `p4c.sh`  
