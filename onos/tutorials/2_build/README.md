# Tutorial 2 - Build the ONOS App With Maven

We are going to build ONOS App with template in this tutorial.

---
## 2.1 Install Maven

**[Apache Maven](https://maven.apache.org/)** is a software project management and comprehension tool. Based on the concept of a project object model (POM), Maven can manage a project's build, reporting and documentation from a central piece of information.

* For **Ubuntu Linux**
    ```bash
    $ sudo apt-get update
    $ sudo apt-get install maven -y
    ```
* For **Mac OS X**
    ```bash
    $ brew install maven
    ```

---
## 2.2 Build a template using Maven

1. Change the current directory into the place you want to place your repository
2. Build a template with Maven (take few minutes)
    ```bash
    # Make sure your current directory is the place you want to place your repository
    mvn archetype:generate -DarchetypeGroupId=org.onosproject -DarchetypeArtifactId=onos-bundle-archetype
    ```
3. During the building, it may ask you set some information about this repository (e.g., maintainer, name, etc.)
    * `groupid` is the name of your organization.
    * `artifactId` is the name of this app.
    ```bash
    Define value for property 'groupId': nctu_nss
    Define value for property 'artifactId': example-app
    Define value for property 'version' 1.0-SNAPSHOT: : 
    Define value for property 'package' nctu_nss : 
    Confirm properties configuration:
    groupId: nctu_nss
    artifactId: example-app
    version: 1.0-SNAPSHOT
    package: nctu_nss
     Y: : y
    ```
4. If succeed, you will see the following messsage:
    ```bash
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time: 17.788 s
    [INFO] Finished at: 2018-12-15T14:03:20+08:00
    [INFO] Final Memory: 22M/461M
    [INFO] ------------------------------------------------------------------------
    ```

---
## 2.3 Modify `pom.xml`

Although we have already created the template for the repository, the description of the repository and the version of packages are needed to be modify.

* Open `pom.xml` and modify the description of repository and the version of ONOS
    ```xml
    <!-- The following is an example! -->
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <onos.version>2.0.0-b1</onos.version>
        <onos.app.name>nctu_nss.example-app</onos.app.name>
        <onos.app.title>Example App</onos.app.title>
        <onos.app.origin>NCTU NSSLAB</onos.app.origin>
        <!--
        <onos.app.category>default</onos.app.category>
        <onos.app.url>http://onosproject.org</onos.app.url>
        <onos.app.readme>ONOS OSGi bundle archetype.</onos.app.readme>
        -->
    </properties>
    ```

---
## 2.4 Hello world, ONOS!

1. Open `./example-app/src/main/java/<ORG_NAME>/AppComponent.java` and find out the following code:
    ```java
    ...
    public class AppComponent {

        private final Logger log = LoggerFactory.getLogger(getClass());

        @Activate
        protected void activate() {
            log.info("Started");
        }

        @Deactivate
        protected void deactivate() {
            log.info("Stopped");
        }

    }
    ```
    * `@Activate` and `Deactivate` are the descritions in OSGI, which can modulizae the system
2. Add the following code into `AppComponent.java`
    ```java
    @Activate
    protected void activate() {
        log.info("Started");
        // Add the code here!
        log.info("Hello world, ONOS!")
    } 
    ```
    * The above will will make the app print "`Hello world, ONOS!`" when actvating.
3. Make the following code in `./example-app/src/test/java/nctu-nss/AppComponentTest.java` into comment before compiling the app into `.oar` file
    ```java
    public class AppComponentTest {

        private AppComponent component;
        
        @Before
        public void setUp() {
            //component = new AppComponent();
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
## 2.5 Compilation

1. Compile the app with Maven (take few minutes)
    ```bash
    # Make sure your current directory is in ./example-app/
    $ mvn clean install
    ```
2. If succeed, you will get the following message:
    ```bash
    ......
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time: 15.946 s
    [INFO] Finished at: 2018-12-15T14:45:00+08:00
    [INFO] Final Memory: 34M/476M
    [INFO] ------------------------------------------------------------------------
    ```
    * The compiled app will be put in `./example-app/target/`.
3. Activate the app with ONOS GUI
    1. Open a termial and change the directory into `onos/`
    2. Run ONOS locally on the development machine
        ```bash
        $ bazel run onos-local [--[clean][debug]]
        # Or
        $ ok [clean][debug]
        ```
    3. Use browser to open the ONOS GUI at [http://localhost:8181/onos/ui](http://localhost:8181/onos/ui) 
        * The default username and password is: **onos/rocks**
        ![](https://i.imgur.com/B0H79Zh.png)
        ![](https://i.imgur.com/jw14w8f.png)
    4. Click the bar on the left-top corner and click `Application`
        ![](https://i.imgur.com/ODVXzzt.png)
    5. Click the button `upload an application` on the right-top of the page and upload the `.oar` file of `example-app`
        ![](https://i.imgur.com/vm55tAV.png)
        ![](https://i.imgur.com/TSjPS9I.png)
    6. After uploading, click the button `activate selected application` on the right-top of the page
        ![](https://i.imgur.com/paDdHaA.png)
        ![](https://i.imgur.com/ANa1Fnx.png)
4. View the log via the ONOS CLI in following two approach
    * Attach to the ONOS CLI console
        ```bash
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

        yungshenglu@root > log:display
        ```
    * Login to the ONOS CLI via SSH
        ```bash
        $ ssh -p 8101 onos@0.0.0.0
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

        yungshenglu@root > log:display
        ```
5. You will find a message with "`Hello world, ONOS!`" in the logs
    ```bash
    14:58:12.701 INFO [features-3-thread-1] Starting bundles:
    14:58:12.702 INFO [features-3-thread-1]   nctu_nss.example-app/1.0.0.SNAPSHOT
    14:58:12.705 INFO [features-3-thread-1] Started
    14:58:12.706 INFO [features-3-thread-1] Hello world, ONOS!
    14:58:12.707 INFO [features-3-thread-1] Done.
    ```

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