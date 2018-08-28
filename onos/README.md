# 展示使用 ONOS 上開發 P4 程式

<!-- TOC -->

- [展示使用 ONOS 上開發 P4 程式](#展示使用-onos-上開發-p4-程式)
    - [Build a Template ONOS-APP](#build-a-template-onos-app)
    - [Next Step](#next-step)
        - [編輯 POM 檔案](#編輯-pom-檔案)
        - [編寫 PipeconfLoader](#編寫-pipeconfloader)
        - [編寫 Interpreter](#編寫-interpreter)
        - [編寫 Pipeliner](#編寫-pipeliner)
        - [最後一步: 打包編譯成 oar](#最後一步-打包編譯成-oar)
        - [Installing ONOS app via `onos-app` shell tool](#installing-onos-app-via-onos-app-shell-tool)
        - [Another method to install - build with ONOS BUCK compile](#another-method-to-install---build-with-onos-buck-compile)

<!-- /TOC -->

## Build a Template ONOS-APP

> ONOS 提供的一種方式，快速建立 ONOS app Service 的模板
> 以下就來介紹如何使用

* [安裝 ONOS 環境](https://github.com/toolbuddy/ssfw/blob/master/netdev/install_onos.sh)

* 安裝 maven
    * [Download Page](https://maven.apache.org/download.cgi)
    * [Installation Guide](https://maven.apache.org/install.html)

有了以上的相依性後，就可以透過 ONOS 提供的腳本來做 Template APP 的產生

* 建立 template app
    * 在你的目的地呼叫 `onos-create-app` 指令，便可以建立一個 ONOS APP 模板
    * 這個過程大約在 3~5 min 左右 (端看電腦性能如何)
    * 等到前置動作完成後，便會出現引導程式，依序填入 `groupId`, `artifactId`, `version`, `package` 等性質
        * `groupId` 是代表公司名稱、同一團隊或公司會使用相同的 groupId 來做代表
        * `artifactId` 則是整個專案的名稱，如同這個目錄下的 onos-p4 資料夾 
    * `version`, `package` 都會有 default 值，可以不用特別去指定

按完之後便完成了基本的 bundle！ 可以看到在你建立的 bundle 專案當中會有一個 pom.xml 檔，是為 Bundle 編譯用的資訊

## Next Step

> 到此為止我們建立了基本的 bundle，接下來要 base on 這個  template 繼續：
> * 建立需要的檔案
> * 編輯 pom 檔案
> * 編寫
>    * PipeconfLoader 
>    * Interpreter
>    * Pipeliner

### 編輯 POM 檔案

**在預設 bundle 當中並不會自動啟動程式進入點（`Activate Pipeconf Loader`）**
所以我們需要修改 `pom.xml` 讓 ONOS 知道這個 bundle 是一個 ONOS App 且需要啟用主要的 Component

**可以在 pom.xml 當中看到有個 comment 區塊：**
```xml
<!-- Uncomment to generate ONOS app from this module.
<onos.app.name>org.foo.app</onos.app.name>
<onos.app.title>Foo App</onos.app.title>
<onos.app.origin>Foo, Inc.</onos.app.origin>
<onos.app.category>default</onos.app.category>
<onos.app.url>http://onosproject.org</onos.app.url>
<onos.app.readme>ONOS OSGi bundle archetype.</onos.app.readme>
-->
```

可以將這塊區域 uncomment 掉，並做適當的修改後即可。
讓 pom.xml 正確的指到我們要的專案資訊即可：
* `onos.app.name`
* `onos.app.title`
* `onos.app.origin`
* `onos.app.category`: `pipeconf`
* `onos.app.url`
* `onos.app.readme`

### 編寫 PipeconfLoader

基本上這個 pipeconfloader 就是一個 ONOS 的 APP，當 ONOS 啟動這個 APP 時，會透過 PiPipeconfService 去註冊 Pipeconf
**以這個例子來說**，我們希望 Pipeconf 擁有 `Interpreter` 以及 `Pipeliner` 兩種 **driver behavior**，以及使用 bmv2 json + p4info

Pipeconf ID 的部份則是會用在 devide config 當中。

這個 App (oar) 在被 ONOS 載入後，會呼叫這個 `activate()`，此時便會將 pipeconf 載好。

而 deavtivate 的部份僅需使用 Pipeconf service 中的 `remove` 即可。

### 編寫 Interpreter

**Interpreter** 主要是處理一些將 ONOS ***一般的 API 轉換成 PI API*** 的工作，一一來看到每一個需要*實作的函式功能*：

* `mapCriterionType`: 
    * 將 ONOS 一般的 Criterion 轉換成 PI match 欄位，舉例來說，如果一個 ONOS App 使用普通的 Criterion 像是 ETH_DST，則會透過這個方法進行轉換。
* `ｍapPiMatchFieldId`: 
    * 和上一個 function 功能相反，是將 PI match 欄位轉換成普通 Criterion

* `mapFlowRuleTableId`: 
    * 將 **數字 Id** 轉換成 P4 一樣使用字串的 Id
    * 例如 ONOS 許多功能都會使用 table 0，而自行定義的 Pipeline 若需要支援一些常用的 ONOS service，則可能會需要這個轉換的功能
* `mapPiTableId`:
    * 和上一個 function 功能相反，將字串 Id 轉換回數字 Id

* `mapTreatment`:
    * 將 ONOS 的 TrafficTreatment 加上 `TableId` 轉換成 `PiAction`，這主要是**解決多個 Action 對到單一個 Action** 的問題。
    * OpenFlow 允許一個 Match 執行多個 Action， 但是 P4 上 Match/Action 只有 **一對一** 的支援，因此會需要這樣的轉換。

* `mapOutboundPacket`:
    * 將 `ONOS PacketOut` 轉換成 PI 格式，即 metadata + payload
    * 這部份是因為開發者可以透過 P4 語言定義接收端的 metadata 格式，因此需要另外定義
* `mapInboundPacket`:
    * 同理，因為開發者可以定義 metadata，以及可以***定義非正規網路協定***，因此需要另外寫轉換用的 function


### 編寫 Pipeliner

Pipeliner 是專門將 FlowObjective 轉換成 Flow + Group 的一個組件
> 詳細的 Flow Objective 可以參考 2017 年 ONOS Build 演講: https://www.youtube.com/watch?v=c3OESLdAgQk&feature=youtu.be
> 

Pipeliner 主要是需要處理三種不同的 **FlowObjective**:
* `FilteringObjective`: 
    * 用來表示 "允許" 或是 "擋掉" 封包進入 Pipeliner 的規則
    * 有時候還會有附帶一些處理的 Action，像是 packet-in 到 ONOS，或是 **更改 header** 等等。

* `ForwardingObjective`:
    * 用來描述封包在 Pipeliner 中需要如何處理、可能是送至 ONOS，或是將封包傳給**特定某些 egress table** 處理等等。

* `NextObjective`:
    * 用來描述 Egress table 裏面需要放置什麼樣的東西，每一個 NextObjective 都會有一個獨立的 Id
    * `ForwardingObjective` 可以透過此 Id 來決定該封包要給哪一個 Egress 規則處理

我們可以參考 onos 上頭 [DefaultPipeconf.java]](https://github.com/opennetworkinglab/onos/blob/master/core/api/src/main/java/org/onosproject/net/pi/model/DefaultPiPipeconf.java) 這支程式內所做的範例，作為一個 `single-table` 的 pipeliner 展示

### 最後一步: 打包編譯成 oar

上述步驟完成後，即可於這個透過 `onos-create-app` 建立的專案根目錄底下直接執行 ***`mvn clean install`*** 指令，執行完後會產生一些編譯好的檔案（附圖為原本文章）：

![](https://i.imgur.com/OQfb3j1.png)
* 可以看到， 這個 `testpipeline-1.0-SNAPSHOT.oar` 即是我們要的檔案，於 ONOS 執行時可透過 `onos-app` 載入到 ONOS 當中！！

> 由於目前還不會開發，所以直接拿 onos-create-app 後的程式下去直接做 `mvn clean install` 的打包:
> ![](https://i.imgur.com/zjXFEB3.png)
> (注意！ 要記得到預設 pom.xml 內把註解的項目給 uncomment！ 這樣才會編譯出 `.oar` !)
> 有了 .oar 就可以把他拿到 ONOS 當中當作一個 Service 啟動囉！

### Installing ONOS app via `onos-app` shell tool

我們如何向 ONOS 註冊一個我們自己寫的 application ? 其中 ONOS 提供了一個 `onos-app` 的指令（一樣是透過 shell script 完成）
> 我個人是透過 `locate onos-app` 去查找，列出的項目非常的多，我選擇 `/home/kevin/onos/tools/package/runtime/bin/onos-app` 這一個來檢視
> 

回到正題，我們現在有了 onos application 後，便可以把他裝進 ONOS 當中。 這時我們可以透過 ONOS 提供的這個 onos-app 來做操作。
可以輸入 `onos-app -h` 來看他支援的操作：
```bash
usage: onos-app [options] <node-ip> list
       onos-app [options] <node-ip> {install|install!} <app-file>
       onos-app [options] <node-ip> {reinstall|reinstall!} [<app-name>] <app-file>
       onos-app [options] <node-ip> {activate|deactivate|uninstall} <app-name>

options: [-P port] [-u user] [-p password] [-v]
```

* 以安裝來說，我們可以直接輸入: 
    ```bash
    onos-app $OC1 install target/<app.name>-<version>.oar
    ```
    * 這個 $OC1 是一個 node-ip，可以直接在你的系統中 echo 看看，會列出一組 ipv4 的 address
    * `target/` 的 prefix 是因為在 mvn clean install 時，所產生的結果會放在 target/ 底下，包括我們最終結果 - *.oar
    * 再透過 install 的動作把 .oar 輸入
    * 有趣的是，可以看到 onos-app 的操作，是透過 curl 幫你包裝 REST API，所以本質上還是走 REST API 的方式做載入
    ```bash
    ... 
    install!|install)
        [ $cmd = "install!" ] && activate="?activate=true"
        [ $# -lt 3 -o ! -f $app ] && usage
        $curl -X POST $HDR $URL$activate --data-binary @$app
        ;;
    ...
    ```

### Another method to install - build with ONOS BUCK compile

除了透過安裝的方式之外，新的 ONOS APP 也可以透過修改 BUCK 檔案來做加入

以 onos 版本 `1.14.0-SNAPSHOT` 為例，需要修改的檔案有：
* `modules.defs`
    > Notice: 在 1.14 版本開始，會轉移使用 Bazel 做編譯
    > 
    * 以我的改動為例，我把新的模組加入在 onos/apps/p4tutorials 底下，則會需要把這份檔案當中找到對應的模組 (`apps`) 下加入這筆 imslab 的 entry: ![](https://i.imgur.com/GE5ymbM.png) 
* `onos/apps/p4-tutorials/imslab/BUCK`
    * `imslab` 是我建立的目錄
    * BUCK 是 bazel 穩定前的穩定版本（目前的實驗環境還是用 BUCK）
    * 而內容我是直接複製 pipeconf 的內容，所以這個 BUCK file 只要修改幾個地方就好，成為：
    ```BUCK=
    COMPILE_DEPS = [
        '//lib:CORE_DEPS',
        '//lib:minimal-json',
        '//protocols/p4runtime/model:onos-protocols-p4runtime-model',
        '//drivers/default:onos-drivers-default',
        '//protocols/p4runtime/api:onos-protocols-p4runtime-api',
    ]

    osgi_jar (
        deps = COMPILE_DEPS,
    )

    BUNDLES = [
        '//apps/p4-tutorial/imslab:onos-apps-p4-tutorial-imslab',
    ]

    onos_app (
        app_name = 'org.onosproject.p4tutorial.imslab',
        title = 'P4 Tutorial Pipeconf - IMSLAB clone',
        category = 'Pipeconf',
        url = 'http://onosproject.org',
        description = 'Provides pipeconf for the ONOS-P4 Tutorial',
        included_bundles = BUNDLES,
        required_apps = [
            'org.onosproject.drivers.p4runtime',
        ]
    )

    ```

以上加完便是完成新的相依性，之後透過重新編譯 onos - `$ONOS_ROOT/tools/build/onos-buck build onos --show-output` 後即可看到新的 app 出現

這麼一來便完成了新的 app 模組的加入，可以在 onos 的運行 `$ONOS_ROOT/tools/build/onos-buck run onos-local -- clean debug` 後看到這個新的模組！

![](https://i.imgur.com/kws3But.png)