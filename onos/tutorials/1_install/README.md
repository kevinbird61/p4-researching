# Tutorial 1 - Installation

We are going to install ONOS in this tutorial.

---
## 1.1 Getting started

* The following packages are reuqired:
  * git
    ```bash
    $ sudo apt-get install git -y
    ```
  * zip
    ```bash
    $ sudo apt-get install zip -y
    ```
  * curl
    ```bash
    $ sudo apt-get install curl -y
    ```
  * unzip
    ```bash
    $ sudo apt-get install unzip -y
    ```
  * Python 2.7
    ```bash
    $ sudo apt install python2.7 python-pip -y
    ```
  * Oracle JDK8
    ```bash
    $ sudo apt-get install software-properties-common -y && \
    sudo add-apt-repository ppa:webupd8team/java -y && \
    sudo apt-get update && \
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections && \
    sudo apt-get install oracle-java8-installer oracle-java8-set-default -y
    ```

---
## 1.2 Build ONOS from source

ONOS is built with [Bazel](https://bazel.build/), an open-source build tool developed by Google. ONOS supports **Bazel 0.17** You can download it from official website or package manager (e.g. `apt`, `brew`, etc.)

1. Download the script `bazel-0.20.0-installer-linux-x86_64.sh` [here](https://github.com/bazelbuild/bazel/releases) 
2. Install **Bazel** with `./scripts/`
    ```bash
    # Make sure you have download ./scripts/
    # Run the Bazel installer as follows
    $ chmod +x bazel-0.20.0-installer-linux-x86_64.sh
    $ ./bazel-0.20.0-installer-linux-x86_64.sh --user
    # Set up your environment or add the following command into ~/.bashrc
    $ export PATH="$PATH:$HOME/bin"
    # If you add the above command into ~/.bashrc, then do the following command
    $ . ~/.bashrc
    ```
3. Clone the source code from ONOS Gerrit repository
    ```bash
    $ git clone https://gerrit.onosproject.org/onos
    ```
4. Add ONOS developer environment to your bash profile (i.e., `.bash` or `.bash_profile`), no need to do this step again if you had done this before
    ```bash
    # Change the directory into onos
    $ cd onos
    # Add ONOS environment to your bash profile
    $ cat << EOF >> ~/.bashrc
    export ONOS_ROOT="`pwd`"
    source $ONOS_ROOT/tools/dev/bash_profile
    EOF
    $ . ~/.bashrc
    ```
5. Build ONOS with Bazel (take several minutes)
    ```bash
    # Make sure your current directory is onos
    # Build ONOS with Bazel
    $ bazel build onos
    ```

---
## 1.3 Start ONOS on local machine

1. Run ONOS locally on the development machine
    ```bash
    $ bazel run onos-local [--[clean][debug]]
    # Or
    $ ok [clean][debug]
    ```
2. Use browser to open the ONOS GUI at [http://localhost:8181/onos/ui](http://localhost:8181/onos/ui) 
    * The default username and password is: **onos/rocks**
    ![](https://i.imgur.com/B0H79Zh.png)
    ![](https://i.imgur.com/jw14w8f.png)
    
---
## 1.4 Interact with ONOS 

* To attach to the ONOS CLI console, run the following command in another terminal:
    ```bash
    # Attach to the ONOS CLI console
    $ onos localhost
    Welcome to Open Network Operating System (ONOS)!
          ____  _  ______  ____     
         / __ \/ |/ / __ \/ __/   
        / /_/ /    / /_/ /\ \     
        \____/_/|_/\____/___/     
                                
    Documentation: wiki.onosproject.org      
    Tutorials:     tutorials.onosproject.org 
    Mailing lists: lists.onosproject.org     

    Come help out! Find out how at: contribute.onosproject.org 

    Hit '<tab>' for a list of available commands
    and '[cmd] --help' for help on a specific command.
    Hit '<ctrl-d>' or type 'logout' to exit ONOS session.

    yungshenglu@root >
    ```
* **Unit Tests**
    To run ONOS unit tests, including code Checkcyle validation, run the following command:
    ```bash
    $ bazel query 'tests(//...)' | xargs bazel test
    # Or
    $ ot
    ```

---
## 1.5 Register ONOS into `systemd` (optional)

1. Copy the script for setup ONOS into `init.d`
    ```bash
    $ sudo cp /opt/onos/init/onos.initd /etc/init.d/onos
    ```
2. Register the ONOS service into `systemd`
    ```bash
    $ sudo cp /opt/onos/init/onos.service /etc/systemd/system/
    $ sudo systemctl daemon-reload
    $ sudo systemctl enable onos
    ```
3. Control the ONOS service
    ```bash
    $ sudo systemctl {start|stop|status|restart} onos.service
    ```

---
## 1.6 ONOS with Mininet

1. Build a simple topology in Mininet in another terminal
    ```bash
    $ sudo mn --topo tree,2,3 --mac --switch ovsk --controller=remote,ip=127.0.0.1
    *** Creating network
    *** Adding controller
    Connecting to remote controller at 127.0.0.1:6653
    *** Adding hosts:
    h1 h2 h3 h4 h5 h6 h7 h8 h9 
    *** Adding switches:
    s1 s2 s3 s4 
    *** Adding links:
    (s1, s2) (s1, s3) (s1, s4) (s2, h1) (s2, h2) (s2, h3) (s3, h4) (s3, h5) (s3, h6) (s4, h7) (s4, h8) (s4, h9) 
    *** Configuring hosts
    h1 h2 h3 h4 h5 h6 h7 h8 h9 
    *** Starting controller
    c0 
    *** Starting 4 switches
    s1 s2 s3 s4 ...
    *** Starting CLI:
    mininet>
    ```
    > More information about [Mininet](http://mininet.org/)
2. View the topology on [http://localhost:8181/onos/ui](http://localhost:8181/onos/ui)
    ![](https://i.imgur.com/iw6wwnr.png)
    * You will only see switches in the toplogy!
3. Because the Open vSwitch has not know the hosts, we are going to ping all hosts in the Mininet
    ```bash
    # Ping all hosts in the Mininet topology
    mininet> pingall
    *** Ping: testing ping reachability
    h1 -> h2 h3 h4 h5 h6 h7 h8 h9 
    h2 -> h1 h3 h4 h5 h6 h7 h8 h9 
    h3 -> h1 h2 h4 h5 h6 h7 h8 h9 
    h4 -> h1 h2 h3 h5 h6 h7 h8 h9 
    h5 -> h1 h2 h3 h4 h6 h7 h8 h9 
    h6 -> h1 h2 h3 h4 h5 h7 h8 h9 
    h7 -> h1 h2 h3 h4 h5 h6 h8 h9 
    h8 -> h1 h2 h3 h4 h5 h6 h7 h9 
    h9 -> h1 h2 h3 h4 h5 h6 h7 h8 
    *** Results: 0% dropped (72/72 received)
    mininet>
    ```
4. View the topology on [http://localhost:8181/onos/ui](http://localhost:8181/onos/ui)
    ![](https://i.imgur.com/LL9wu7I.png)
    * Press `H` to show all hosts in topology
    * Press `P` to highlight the port of each link
    * Press `T` to change into night mode

---
## References

* [GitHub - opennetworkinglab/ONOS](https://github.com/opennetworkinglab/onos/tree/master)
* [ONOS Wiki](https://wiki.onosproject.org/)
* [ONOS 從零入門教學 （應用程式新增，安裝及測試）](http://blog.laochanlam.me/2017/09/16/ONOS-%E5%BE%9E%E9%9B%B6%E5%85%A5%E9%96%80%E6%95%99%E5%AD%B8-%E6%87%89%E7%94%A8%E7%A8%8B%E5%BC%8F%E6%96%B0%E5%A2%9E-%E5%AE%89%E8%A3%9D%E5%8F%8A%E6%B8%AC%E8%A9%A6/)
* [Google Group - ONOS Developer](https://groups.google.com/a/onosproject.org/forum/#!forum/onos-dev)

---
## Contributors

ONOS code is hosted and maintained using [Gerrit](https://gerrit.onosproject.org/). Code on [GitHub](https://github.com/opennetworkinglab/onos/tree/master) is only a mirror. The ONOS project does **NOT** accepte code through pull request on GitHub. To contribute to ONOS, please refer to [Sample Gerrrit Workflow](https://wiki.onosproject.org/display/ONOS/Sample+Gerrit+Workflow). It should includes most of things you'll need to get your contribution started!

* [David Lu](https://github.com/yungshenglu)


---
## License

ONOS (Open Network Operating System) is published under Apache License 2.0