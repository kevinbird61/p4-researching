# Constructor invocations

> Reference: https://p4.org/p4-spec/docs/P4-16-v1.1.0-draft.html#sec-constructor

幾個於 compilation time 做記憶體配置（allocate resources）的 P4 constructs: 
* extern objects
* parsers
* control blocks
* packages

而這些物件的 *宣告* 可以透過兩種方式來建立：
* 使用 `constructor invocations` (像是 `package(...)` 內呼叫每個 control block )
* 使用 `instantiations` （像是 counter、register 等 extern objects 的宣告方式，詳細可以參考 [10.3 Instantiations 章節](https://p4.org/p4-spec/docs/P4-16-v1.1.0-draft.html#sec-instantiations) ）

constructor invocations 的語法與 function call 類似，而 constructors 會在 compilation-time 時期就完整的被評估（詳細部份參考 [`spec Ch17 - P4 abstract machine: Evaluation`](https://p4.org/p4-spec/docs/P4-16-v1.1.0-draft.html#sec-p4-abstract-mach)）

而在 table 中的使用，可以看到這樣的用法：
```p4
/* architecture model */
extern ActionProfile {
    ActionProfile(bit<32> size);  // constructor
}

/* your package */
table tbl {
    actions = { ... }
    implementation = ActionProfile(1024);  // constructor invocation
}
```