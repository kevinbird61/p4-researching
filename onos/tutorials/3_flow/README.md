# Tutorial 3 - Add Flow Entry in ONOS

We are going to practice how to add flow entry in ONOS in this tutorial. Besides, we are going to use the example program ([`SimpleForwarding.java`](SimpleForwarding.java)).

---
## 3.1 Framework

We provide an example code ([`SimpleForwarding.java`](SimpleForwarding.java)) which includes the following parts. 
* `activate`
* `processor`
* `installRule`
* `packetOut`
* `flood`
* `deactivate`

The workflow of `SimpleForwarding.java` is as follow.
1. Activate the processor
2. When the packet forwarded in controller, the processer start to process the packet
3. Flood the packet or install forwardign rule in flow table 

---
## 3.2 Activate

```java
@Activate
protected void activate() {
    appId = coreService.regirsterApplication("nctu_nss.app");

    packetService.addProcessor(processor, PacketProcessor.director(2));
    TrafficSelector.Builder.selector = DefaultTrafficSelector.builder();
    selector.matchEthType(Ethernet.TYPE_IPV4).matchEthType(Ethernet.TYPE_ARP);

    packetService.requestPackets(selector.build(), PacketPriority.REACTIVE, appId);

    log.info("Started");
}
```

The above code is in `SimpleForwarding.java` and the descriptions are as follow.

1. Register the app and get `appId` which is a globle variable
    ```java
    appId = coreService.registerApplication("nctu_nss.app");
    ```
2. Create a flow entry with matching **the type of Ethernet is ARP or IPv4**
    ```java
    packetService.addProcessor(processor, PacketProcessor.director(2));
    TrafficSelector.Builder.selector = DefaultTrafficSelector.builder();
    selector.matchEthType(Ethernet.TYPE_IPV4).matchEthType(Ethernet.TYPE_ARP);
    ```
3. Add the flow created above into switch
    ```java
    packetService.requestPackets(selector.build(), PacketPriority.REACTIVE, appId);
    ```
    * The flow entry will be as follow:
        | Match | Priority | Action |
        |---|---|---|
        | Ethernet_Type=ARP | REACTIVE(5) | Output=Controller |
        | Ethernet_Type=IPV4 | REACTIVE(5) | Output=Controller |

---
## 3.3 Processor

```java
private class ReactivePacketProcessor implements PacketProcessor {
    @Override
    public void process(PacketContext context) {
        // Stop processing if the packet has been handled, since we cannot do anymore to it.
        if (context.isHandled()) {
            return;
        }

        InboundPacket pkt = context.inPacket();
        Ethernet ethPkt = pkt.parsed();
        if (ethPkt == null) {
            return;
        }

        HostId srcId = HostId.hostId(ethPkt.getSourceMAC());
        HostId dstId = HostId.hostId(ethPkt.getDestinationMAC());

        // Do we know who this is for? If not, flood and bail.
        Host dst = hostService.getHost(dstId);
        if (dst == null || ethPkt.getEtherType() == Ethernet.TYPE_ARP) {
            flood(context);l
            return;
        }
        installRule(context, srcId, dstId);
    }
}
```

The above code is in `SimpleForwarding.java` and the descriptions are as follow.

1. Stop processing if the packet has been handled
    ```java
    if (context.isHandled()) {
        return;
    }
    ```
2. Parser the input packet
    ```java
    InboundPacket pkt = context.inPacket();
    Ethernet ethPkt = pkt.parsed();
    if (ethPkt == null) {
        return;
    }
    ```
3. Get the source and the destination MAC address from the packet
    ```java
    HostId srcId = HostId.hostId(ethPkt.getSourceMAC());
    HostId dstId = HostId.hostId(ethPkt.getDestinationMAC());
    ```
4. If the type of Ethernet is **ARP**, then flood; else install the forwarding rule
    ```java
    // Do we know who this is for? If not, flood and bail.
    Host dst = hostService.getHost(dstId);
    if (dst == null || ethPkt.getEtherType() == Ethernet.TYPE_ARP) {
        flood(context);l
        return;
    }
    installRule(context, srcId, dstId);
    ```

---
## 3.4 Install Rule

```java
private void installRule(PacketContext context, HostId, srcId, HostId dstId) {
    Ethernet inPkt = context.inPacket().parsed();
    TrafficSelector.Builder selectorBuilder = DefaultTrafficSelector.builder();

    Host dst = hostService.getHost(dstId);
    Host src = hostService.getHost(srcId);
    if (src == null || dst == null) {
        return;
    } else {
        selectorBuilder.matchEthSrc(inPkt.getSourceMAC())
            .matchEthDst(inPkt.getDestinationMAC());

        TrafficTreatment treatment = DefaultTrafficTreatment.builder()
            .setOutput(dst.location().port())
            .build()
        
        ForwardingObjective forwardingObjective = DefaultForwardingObjective.builder()
            .withSelector(selectorBuilder.build())
            .withTreatment(treatment)
            .withPriority(10)
            .withFlag(ForwardingObjective.Flag.VERSATILE)
            .fromApp(appId)
            .makeTemporary(10)  // Timeout
            .add();
        
        flowObjectiveService.forward(context.inPacket().receivedFrom().deviceId(), forwardingObjective);

        packetOut(context, PortNumber.TABLE);
    }
}
```

The above code is in `SimpleForwarding.java` and the descriptions are as follow. The differences of "keyword" between OpenFlow and ONOS is as follow:

| ONOS | OpenFlow |
|---|---|
| TrafficSelector | Match |
| TrafficTreatment | Action |

1. Parse the input packet
    ```java
    Ethernet inPkt = context.inPacket().parsed();
    ```
2. Build a traffic selector for matching rule
    ```java
    TrafficSelector.Builder selectorBuilder = DefaultTrafficSelector.builder();
    ```
3. Find out the source host and the destination host are in the topology via `HostService`
    ```java
    Host dst = hostService.getHost(dstId);
    Host src = hostService.getHost(srcId);
    ```
    * To use `HostService`, you need to activate the app `Host Location Provider`. 
    * The app `Host Location Provider` will add some default rule in the system and **forward the ARP packets to ONOS controller**. Thus, you can ignore the ARP packets in `processor`
4. If the source and the destination host are existed in the topology, then create a flow entry with the mathcing rule via `TrafficSelector` and the action via `TrafficTreatment`. 
    ```java
    selectorBuilder.matchEthSrc(inPkt.getSourceMAC())
        .matchEthDst(inPkt.getDestinationMAC());
    
    TrafficTreatment treatment = DefaultTrafficTreatment.builder()
        .setOutput(dst.location().port())
        .build();
    
    ForwardingObjective forwardingObjective = DefaultForwardingObjective.builder()
        .withSelector(selectorBuilder.build())
        .withTreatment(treatment)
        .withPriority(10)
        .withFlag(ForwardingObjective.Flag.VERSATILE)
        .fromApp(appId)
        .makeTemporary(10) //timeout
        .add();
    ```
5. Add the flow entry via `FlowObjectiveService`
    ```java
    flowObjectiveService.forward(context.inPacket().receivedFrom().deviceId(), forwardingObjective);
    ```
6. Set the number of port for packet-out to make the packet be processed by the flow table with rules
    ```java
    packetOut(context, PortNumber.TABLE);
    ```

---
## 3.5 Packet-out

```java
private void packetOut(PacketContext context, PortNumber portNumber) {
    context.treatmentBuilder().setOutput(portNumber);
    context.send();
}
```

The above code is in `SimpleForwarding.java` and the descriptions are as follow.

1. Set the number of port for the traffic treatment
    ```java
    context.treatmentBuilder().setOutput(portNumber);
    ```
2. Trigger the outbound packet to be sent
    ```java
    context.send();
    ```

---
## 3.6 Flood

```java
private void flood(PacketContext context) {
    if (topologyService.isBroadcastPoint(topologyService.currentTopology(), context.inPacket().receivedFrom())) {
        packetOut(context, PortNumber.FLOOD);
    } else {
        context.block();
    }
}
```

The above code is in `SimpleForwarding.java` and the descriptions are as follow.

1. Check whether broadcast is allowed for traffic received on the specifed connection point
    ```java
    if (topologyService.isBroadcastPoint(topologyService.currentTopology(), context.inPacket().receivedFrom()))
    ```
2. If the connection is in the topology, then flood via `packetOut`
    ```java
    packetOut(context, PortNumber.FLOOD);
    ```
3. Otherwise, block the outbound packet from being sent
    ```java
    context.block();
    ```

---
## 3.7 Deactivate

```java
@Deactivate
protected void deactivate() {
    packetService.removeProcessor(processor);
    processor = null;
    log.info("Stopped");
}
```

The above code is in `SimpleForwarding.java` and the descriptions are as follow.

1. Remove the processor of packets service
    ```java
    packetService.removeProcessor(processor);
    ```
2. Make the processor point at `null` to end the app
    ```java
    processor = null;
    ```

---
## 3.8 Build the ONOS app with Maven

> You can refer to the tutorial "[Build a ONOS App With Maven](2_build/)"

1. Build a template with Maven (take few minutes)
    ```bash
    # Make sure your current directory is the place you want to place your repository
    mvn archetype:generate -DarchetypeGroupId=org.onosproject -DarchetypeArtifactId=onos-bundle-archetype
    ```
2. During the building, it may ask you set some information about this repository (e.g., maintainer, name, etc.)
    * `groupid` is the name of your organization.
    * `artifactId` is the name of this app.
    ```bash
    Define value for property 'groupId': nctu_nss
    Define value for property 'artifactId': simple-forwarding
    Define value for property 'version' 1.0-SNAPSHOT: : 
    Define value for property 'package' nctu_nss : 
    Confirm properties configuration:
    groupId: nctu_nss
    artifactId: simple-forwarding
    version: 1.0-SNAPSHOT
    package: nctu_nss
     Y: : y
    ```
3. If succeed, you will see the following messsage:
    ```bash
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time: 25.497 s
    [INFO] Finished at: 2018-12-15T20:10:06+08:00
    [INFO] Final Memory: 19M/310M
    [INFO] ------------------------------------------------------------------------
    ```
4. Modify `pom.xml`
    ```xml
    <!-- The following is an example! -->
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <onos.version>2.0.0-b1</onos.version>
        <onos.app.name>nctu_nss.simple-forwarding</onos.app.name>
        <onos.app.title>Simple Forwarding</onos.app.title>
        <onos.app.origin>NCTU NSSLAB</onos.app.origin>
        <!--
        <onos.app.category>default</onos.app.category>
        <onos.app.url>http://onosproject.org</onos.app.url>
        <onos.app.readme>ONOS OSGi bundle archetype.</onos.app.readme>
        -->
    </properties>
    ```
5. Add the following scripts in the tag `<dependencies>` of `pom.xml`
    ```xml
    <!-- Add the dependency here! -->
    <dependency>
        <groupId>org.apache.felix</groupId>
        <artifactId>org.apache.felix.scr.annotations</artifactId>
        <version>1.12.0</version>
    </dependency>
    ```
6. Replace the file `./simple-forwarding/src/main/java/nctu_nss/AppComponent.java` to `./SimpleForwarding.java`
7. Rename the file `./simple-forwarding/src/test/java/nctu_nss/AppComponentTest.java` to `./simple-forwarding/src/test/java/nctu_nss/SimpleForwardingTest.java`
8. Modify the file `./simple-forwarding/src/test/java/nctu_nss/SimpleForwardingTest.java` as follow
    ```java
    public class SimpleForwardingTest {

        private SimpleForwarding component;
        
        @Before
        public void setUp() {
            //component = new SimpleForwarding();
            //component.activate();

        }

        @After
        public void tearDown() {
            //component.deactivate();
        }

        @Test
        public void basics() {

        }

    }
    ```
    * Make sure you have already commented the code in above before compiling; otherwise, the compilation may go wrong!

---
## 3.9 Compilation

1. Compile the app with Maven (take few minutes)
    ```bash
    # Make sure your current directory is in ./simple-forwarding/
    $ mvn clean install
    ```
2. If succeed, you will get message as follow:
    ```bash
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time: 3.984 s
    [INFO] Finished at: 2018-12-15T17:34:39+08:00
    [INFO] Final Memory: 31M/458M
    [INFO] ------------------------------------------------------------------------
    ```
    * The compiled app will be put in `./simple-forwarding/target/`.
3. How to activate the app with ONOS GUI?
    Please refer to the **section 2.5** in the tutorial "[Build a ONOS App With Maven](2_build/)"

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