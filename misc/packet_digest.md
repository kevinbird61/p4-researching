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

## Digest 的運行過程（待確認）

* 從 spec 與 p4runtime.proto 上來看，可以知道在 switch 上呼叫 pack() 後， digest 的訊息格式會在 switch 上做累積; 而 control plane 能夠透過 Read request 的方式來對 switch 做詢問、察看現有 digest Entry 的 `digest_id`。

* 之後透過 StreamChannel 做 `StreamMessageRequest`/`StreamMessageResponse`， 以 DigestListAck 去跟 switch 上用 digest_id, list_id 拿其對應到的 DigestEntry （實際上 switch 上頭打包的資訊）。而 switch 的回應則會透過 StreamMessageResponse 中的 DigestList 做資料回傳。


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