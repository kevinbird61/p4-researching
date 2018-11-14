# `implementation` (table)

> 參考 P4 spec [Chapter 13 - Table properties](https://p4.org/p4-spec/docs/P4-16-v1.1.0-draft.html#sec-table-props), 13.2.1.6: Additional properties

`implementation` 這項性質可以用來傳額外的資訊給 compiler back-end， 而這項性質的值可以透過 extern block 從適合的 components 的 library 來建立。 舉例來說， P4_14 table 的 core functionality `action_profile` constructs 能夠於其架構上來實作這項功能來支援這 feature :

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