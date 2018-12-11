# Packet Digest

> Source: [PSA Spec #Packet-Digest](https://p4.org/p4-spec/docs/PSA.html#sec-packet-digest)

* Digest 是其中從 data plane 上送訊息到 control plane 的方式。
    * 另一種方式是透過 `設定 port 成為 PSA_PORT_CPU`（也就是一般認知的 `packet_in`
    * 而設定 PSA_PORT_CPU 的方法，則會把所有 packets （header 之外同時包括 payload）
    * 而 digest 則能夠縮小這樣回報封包的內容。
    * 而在 PSA 實作當中，則利用了這個概念，並做升級: 他結合多個 packets 形成一個較大的 messages，進而組成 `digest`，進而降低對 control plane 的負擔（比起以往 per-packet 的 packetin rate）


> 不過透過 P4 內 annotation 語法 - `@controller_header("packet_in")`） 來做特殊 header 的標示，這個功能也能夠達到類似的功能？

* Digest 可以裝各式 data plane 內的資訊，由於 P4 program 能有多種 Digest instances，每個都能有不同的資料格式（base on 需求而定），讓外部 control plane 能夠蒐集這些不同格式的資料（PSA 實作需要提供區分這些不同 Digest instances 之間的訊息的能力）

* 於 PSA 當中， digest 透過 `pack()` 的呼叫來建立 digest instance，其使用的 argument 為 P4 struct type：
```p4
// Digest 宣告
struct mac_learn_digest_t {
    EthernetAddress srcAddr;
    PortId_t        ingress_port;
}

...

control IngressDeparserImpl(packet_out packet,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers hdr,
                            in metadata meta,
                            in psa_ingress_output_metadata_t istd)
{
    CommonDeparserImpl() common_deparser;
    Digest<mac_learn_digest_t>() mac_learn_digest;
    apply {
        if (meta.send_mac_learn_msg) {
            mac_learn_digest.pack(meta.mac_learn_msg);
        }
        common_deparser.apply(packet, hdr);
    }
}

```

* 在 spec 當中也提到， PSA program 能夠建立數個 Digest instances 於相同的 IngressDeparser control block，並且在這個 control block 當中對每個 instances 都做一次 `pack()` 的呼叫。（而 PSA 實作並不需要對 EgressDeparser control block 中支援 Digest 的使用）

* 對於同一個 packet 所產生的多個 Digest messages，spec 建議 PSA 實作上是採用其所產生的順序作為傳送 Digest messages 的順序。

* 而 digest 產生的速度可能大於 control plane 能夠接收的速度，造成 loss 的可能性。 Spec 建議可以用個 counter 來計算 digest messages 產生、但還沒到 control plane 的數量。

## Digest 的運行過程

### From Spec. Definition

* 從 spec 與 p4runtime.proto 上來看，可以知道在 switch 上呼叫 pack() 後， digest 的訊息格式會在 switch 上做累積; 而 control plane 能夠透過 Read request 的方式來對 switch 做詢問、察看現有 digest Entry 的 `digest_id`。

* 之後透過 StreamChannel 做 `StreamMessageRequest`/`StreamMessageResponse`， 以 DigestListAck 去跟 switch 上用 digest_id, list_id 拿其對應到的 DigestEntry （實際上 switch 上頭打包的資訊）。而 switch 的回應則會透過 StreamMessageResponse 中的 DigestList 做資料回傳。

### 整體運行流程

* 這部份的理解來自於實作 digest 的範例所得，可以參考專案底下的 P4 練習程式碼。並且參考 p4lang/p4runtime 底下的 protobuf 的腳本檔來做進一步的確認。
* 從 p4runtime.proto 當中，可以看到跟 Digest 有關的通道有兩種，第1種是單向的 RPC、另一種則是 bidirectional 的 stream channel。
* 其中單向 RPC 中的 DigestEntry 便是用來 "configure" target device 的行為 - 如何去產生 Digest Message 到 controller 去。這個 Message Type 並非是用來夾帶 target device 上打包好的 Digest Message，而是專門作為 "設定" 而存在的。
    * 我們從 controller 端發送出 DigestEntry 的 WriteRequest 到 target device 上，透過 Request 當中 DigestEntry 內的 config 欄位來設定
* 用來送 Digest Message 的封包的則是用 Stream channel - "DigestList" (target to controller) / "DigestListAck" (controller to target)
    * 而跟 PacketIn/Out 一樣，由於是 bidirectional 的方式，可以透過 p4runtime 提供的 library 對 DigestList 的 channel 做 listening 

* 關於 DigestEntry:
    * 在 p4runtime 專案當中可以看到，目前的規格是有 `digest_id` 以及 `config` 這兩個欄位資料。其中 config 又可以細分為三項設定：
        * max_timeout_ns: maximum server buffering deley.
        * max_list_size: maximum digest list size.（一次從 target 送到 controller 的 digest message 數量）
        * ack_timeout_ns: server 等待 controller 送回 DigestListAck 的 timeout value。 （ *Before new digest message can be generated for the same learned data* ）
        > ns: nano second
    * 而 DigestEntry 的 Update Type 的使用也有他獨立的意義（與一般 Pipeline control 的使用有別）

* 嚴格來說，P4 spec 內並沒有強制加上 digest 的實作細節的限制，其精神在於提供另一種有別於 PacketIn 打整個封包到 control plane 的方法，能夠只抽取必要的資訊，並透過 grpc bidirectional stream channel、將目前所有的 digest message 以串列/陣列的型式傳給 control plane。


## 而 v1model.p4 的 digest 呼叫

> 參考: https://github.com/jafingerhut/p4-guide/blob/master/control-plane-types/prog1-v1model.p4

由於 P4 在 psa.p4 及 v1model.p4 上面所支援的 digest 呼叫不同，所以這邊由 P4 社群的大佬寫的 v1model.p4 呼叫方式（其實與 psa 差不多）：

* v1model.p4 當中的定義: 
```p4
extern void digest<T>(in bit<32> receiver, in T data);
```

* 於 action 當中的寫法：
```p4
digest<mac_learn_digest>(
    (bit<32>) 1024,
    { 
        hdr.eth.srcAddr,
        standard_metadata.ingress_port
    }
);
```

相比於 psa 的 digest， v1model.p4 裡頭的 digest 就沒有一個 pack 的指令可供呼叫（即是在呼叫當下就送出 digest packet）