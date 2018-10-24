# Properties of Action

* `Table` 宣告了基本的`控制平面 (control plane)`以及`資料平面 (data plane)`的介面 (interfaces)，像是 `keys` 以及對應的 `actions`
* 然而實作一個 table 最好的方式，還是依據該 table 在 runtime 時期被安裝的 entries 數量。
    * 舉例來說，table 如果以 `size = <arbitrary number>` 來做宣告，則在運行時期可以成為密集或是稀疏的表，可以實作 hash-tables、associative memories、tries 等等。
* 此外，一些架構（e.g. psa、v1model 等等，或是其他廠商提供的架構）可能支援 **額外的 table 性質**（並且這個性質不是定義於 P4 spec 內，其 semantics 並不會 follow P4-16/14 實作）
    * 舉例來說，在某些架構當中 table resources 是靜態宣告的，那麼 programmer 就需要用 `size=<number>` 這個 table property 來做定義，讓其編譯器後端可以使用它來分配存儲資源。

## `implementation`

* 用來傳 **額外的資訊** 給編譯器後端。
* 這項性質可以用 extern block 的 instance 作為其值。以 P4_14 table `action_profile` 來看，便是用了這個性質：
```p4
extern ActionProfile {
   ActionProfile(bit<32> size); // number of distinct actions expected
}
table t {
    key = { ...}
    size = 1024;
    implementation = ActionProfile(32);  // constructor invocation
}
```
* 在這邊 action profile 是用來優化 table 的。 當 table 的 entries 特別多，但是與這些 entries 相關聯的 action 預計會在少量不同的值上進行，那麼這個功能就能夠優化： 藉由加入一層 indirection，能夠分享相同的 entries，這使得 table 所使用的 *存儲資源* 能有明顯的下降。

## Action Selector

* [action_selector](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4#L140) 是 v1model 以及 PSA 架構的 `extern`，不是 P4 內建的，可以參考在 [v1model.p4](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4#L27) 內新增的 match_kind:
```p4
match_kind {
    range,
    // Used for implementing dynamic_action_selection
    selector
}
```

* selector 用來標記說哪些欄位是用來 hash 的，而 Hash 過的值會被用來選擇 group 裡面的 member （使用哪個 action）
* 而在 Controller 使用時，需要下 action profile member ID & group ID 到switch 中
* 可以當作是比較高階、特殊的 Matching 機制

## `One shot Action Selector Programming`

> [spec](https://s3-us-west-2.amazonaws.com/p4runtime/docs/v1.0.0-rc3/P4Runtime-Spec.html#sec-oneshot)

* P4Runtime supports `syntactic sugar` to program a table, which is implemented with an `action selector`, in one shot. One shot means that a table entry, an action profile group, and a set of action profile members can be programmed with a single update message. Using one shots has the advantage that the controller does not need to keep track of group ids and member ids.