# P4 Switch/Host wrapper of mininet 

# std libs
from sys import exit
from time import sleep 
import os 
import socket
import tempfile

# Mininet libs
from mininet.net import Mininet
from mininet.node import Switch,Host
from mininet.log import setLogLevel, info, error, debug
from mininet.moduledeps import pathCheck

# self-defined libs
from netstat import check_listening_on_port
SWITCH_START_TIMEOUT = 10 # seconds

# ====================================== P4 Host/Switch + P4Runtime switch ======================================
class P4Host(Host):
    def config(self,**params):
        r = super(P4Host,self).config(**params)

        # change default interface
        self.defaultIntf().rename("eth0")

        # 
        for off in ["rx", "tx", "sg"]:
            cmd = "/sbin/ethtool --offload eth0 %s %s off" % (self.defaultIntf().name, off)
            self.cmd(cmd)

        # disable IPv6
        self.cmd("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
        self.cmd("sysctl -w net.ipv6.conf.default.disable_ipv6=1")
        self.cmd("sysctl -w net.ipv6.conf.lo.disable_ipv6=1")

        return r
    def describe(self):
        print "**********"
        print self.name
        print "default interface: %s\t%s\t%s" %(
            self.defaultIntf().name,
            self.defaultIntf().IP(),
            self.defaultIntf().MAC()
        )
        print "**********"

class P4Switch(Switch):
    """ P4 virtual switch """
    # id of current switch
    device_id = 0

    def __init__(self, name, sw_path=None, json_path=None,
                    thrift_port = None,
                    pcap_dump = False,
                    log_console = False,
                    log_file = None,
                    verbose = False,
                    device_id = None,
                    enable_debugger = False,
                    **kwargs):
        Switch.__init__(self, name, **kwargs)
        assert(sw_path)
        assert(json_path)
        # check sw_path is valid
        pathCheck(sw_path)
        # make sure the json (compiled from P4? or topo.json?) exist
        if not os.path.isfile(json_path):
            error("Invald JSON file.\n")
            exit(1)
        self.sw_path = sw_path
        self.json_path = json_path
        self.verbose = verbose 
        # using tempfile lib (for different platform)
        print tempfile.gettempdir() 
        logfile = tempfile.gettempdir()+"/p4s.{}.log".format(self.name)
        self.output = open(logfile,'w')
        
        # listening on thrift_port
        self.thrift_port = thrift_port
        # FIXME: Need netstat ->
        if check_listening_on_port(self.thrift_port):
            error('%s cannot bind port %d because it is bound by another process\n' % (self.name, self.thrift_port))
            exit(1)
        self.pcap_dump = pcap_dump
        self.enable_debugger = enable_debugger
        self.log_console = log_console

        if log_file is not None:
            self.log_file = log_file
        else:
            self.log_file = tempfile.gettempdir()+"/p4s.{}.log".format(self.name)

        if device_id is not None:
            self.device_id = device_id
            # setting device id for P4 switch !
            P4Switch.device_id = max(P4Switch.device_id, device_id)
        else:
            self.device_id = P4Switch.device_id
            # inc device id, make sure next one won't be duplicated
            P4Switch.device_id += 1
        
        # nanomsg 
        self.nanomsg = "ipc:///tmp/bm-{}-log.ipc".format(self.device_id)

    @classmethod
    def setup(cls):
        pass

    def check_switch_started(self, pid):
        """
            While the process is running (pid exists), we check if the Thrift
            server has been started. If the Thrift server is ready, we assume that
            the switch was started successfully. This is only reliable if the Thrift
            server is started at the end of the init process
        """
        while True:
            if not os.path.exists(os.path.join("/proc",str(pid))):
                return False
            if check_listening_on_port(self.thrift_port):
                return True
            sleep(0.5)

    def start(self, controllers):
        "Start up a new P4 switch"
        info("Starting P4 switch {}.\n".format(self.name))
        args = [self.sw_path]
        for port, intf in self.intfs.items():
            if not intf.IP():
                args.extend(['-i', str(port) + "@" + intf.name])
        if self.pcap_dump:
            args.append("--pcap %s" % self.pcap_dump)
        if self.thrift_port:
            args.extend(['--thrift-port',str(self.thrift_port)])
        if self.nanomsg:
            args.extend(['--nanomsg', self.nanomsg])
        args.extend(['--device-id', str(self.device_id)])

        P4Switch.device_id += 1
        args.append(self.json_path)
        
        if self.enable_debugger:
            args.append("--debugger")
        if self.log_console:
            args.append("--log-console")
        info(' '.join(args)+"\n")

        pid = None

        with tempfile.NamedTemporaryFile() as f:
            # run cmd
            self.cmd(' '.join(args) + ' >' + self.log_file + ' 2>&1 & echo $! >> ' + f.name)
            # get pid
            pid = int(f.read())
        debug("P4 switch {} PID is {}.\n".format(self.name, pid))

        # check switch status
        if not self.check_switch_started(pid):
            error("P4 switch {} didn't start correctly.\n".format(self.name))
            exit(1)
        
        info("P4 switch {} has been started.\n".format(self.name))

    def stop(self):
        "Terminate P4 switch."
        self.output.flush()
        self.cmd('kill %' + self.sw_path)
        self.cmd('wait')
        self.deleteIntfs()

    def attach(self, intf):
        "Connect a data port"
        assert(0)

    def detach(self, intf):
        "Disconnect a data port"
        assert(0)

"""
    P4Runtime Switch (gRPC enable)
"""
class P4RuntimeSwitch(P4Switch):
    "BMv2 switch with gRPC support"
    
    # port usage
    next_grpc_port=50051
    next_thrift_port=9090

    def __init__(self, name, sw_path=None, json_path=None,
                grpc_port=None,
                thrift_port=None,
                pcap_dump=False,
                log_console=False,
                verbose=False,
                device_id=None,
                enable_debugger=False,
                log_file=None,
                **kwargs):
        Switch.__init__(self, name, **kwargs)
        assert (sw_path)
        self.sw_path = sw_path
        # check this sw_path is valid or not
        pathCheck(sw_path)

        if json_path is not None:
            if not os.path.isfile(json_path):
                error("Invalid JSON file.\n")
                exit(1)
            self.json_path = json_path
        else:
            self.json_path = None
        
        # set grpc port
        if grpc_port is not None:
            self.grpc_port = grpc_port
        else:
            self.grpc_port = P4RuntimeSwitch.next_grpc_port
            P4RuntimeSwitch.next_grpc_port += 1

        # set thrift port 
        if thrift_port is not None:
            self.thrift_port = thrift_port
        else:
            self.thrift_port = P4RuntimeSwitch.next_thrift_port
            P4RuntimeSwitch.next_thrift_port += 1

        if check_listening_on_port(self.grpc_port):
            error("%s cannot bind port %d because it is bound by another process.\n" % (self.name, self.grpc_port))
            exit(1)

        self.verbose = verbose
        logfile = tempfile.gettempdir()+"/p4s.{}.log".format(self.name)
        self.output = open(logfile,'w')
        self.pcap_dump = pcap_dump
        self.enable_debugger = enable_debugger
        self.log_console = log_console

        # define log_file
        if log_file is not None: 
            self.log_file = log_file
        else:
            # if not define yet, use logfile instead
            self.log_file = logfile
        
        if device_id is not None:
            self.device_id = device_id
            P4Switch.device_id = max(P4Switch.device_id, device_id)
        else:
            self.device_id = P4Switch.device_id
            P4Switch.device_id += 1
        self.nanomsg = "ipc:///tmp/bm-{}-log.ipc".format(self.device_id)

    
    def check_switch_started(self, pid):
        for _ in range(SWITCH_START_TIMEOUT * 2):
            if not os.path.exists(os.path.join("/proc",str(pid))):
                return False 
            if check_listening_on_port(self.grpc_port):
                return True 
            sleep(0.5)
    
    def start(self, controllers):
        info("Starting P4 Runtime switch {}.\n".format(self.name))

        args = [self.sw_path]
        for port, intf in self.intfs.items():
            if not intf.IP():
                args.extend(['-i', str(port) + "@" + intf.name])
        if self.pcap_dump:
            args.extend("--pcap %s" % self.pcap_dump)
        if self.nanomsg:
            args.extend(['--nanolog', self.nanomsg])
        
        args.extend(['--device-id', str(self.device_id)])
        P4Switch.device_id += 1

        if self.json_path:
            args.append(self.json_path)
        else:
            args.append("--no-p4")

        # open debugger mode 
        if self.enable_debugger:
            args.append("--debugger")

        if self.log_console:
            args.append("--log-console")
        if self.thrift_port:
            args.append("--thrift-port " + str(self.thrift_port))
        if self.grpc_port:
            args.append("-- --grpc-server-addr 0.0.0.0:"+str(self.grpc_port))
        
        cmd = ' '.join(args)
        info(cmd+"\n")
        print cmd+"\n"

        pid = None 
        with tempfile.NamedTemporaryFile() as f:
            self.cmd(cmd + ' >' + self.log_file + ' 2>&1 & echo $! >> ' + f.name)
            pid = int(f.read())
        debug("P4 Runtime switch {} PID is {}.\n".format(self.name, pid))
        if not self.check_switch_started(pid):
            error("P4 Runtime switch {} didn't start correctly.\n".format(self.name))
            exit(1)
        info("P4 Runtime switch {} has been started.\n".format(self.name))