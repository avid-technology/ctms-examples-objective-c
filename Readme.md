Please Read Me
==============

* Implementation:
    * The examples are implemented with Objective-C and the macOS 10.11 SDK using the Cocoa API. - All examples provide a GUI.
    * The examples use REST and HATEOAS.
    * All examples are configured to use a request timeout of 60s.
    * There are some error checks but those are very general and might not cover all cases. Esp. timeouts or unreachable endpoints could happen at any time during the application of REST and HATEOAS.
    * No optimization and no parallelization (e.g. for requesting results from the platform) was implemented.
        * Esp. the examples use HATEOAS to get all links. Instead of HATEOAS all links could be used hard coded or being "bookmarked" without HATEOAS (resulting in faster execution time), but this is not the idea behind RESTful interfaces. Also mind, that those links could change in future so the only save way is to get the via HATEOAS. The examples do only use these URLs directly: https://$apidomain/auth, https://$apidomain/api/middleware/service/ping, https://$apidomain/apis/$servicetype;version=0;realm=$realm/locations and https://$apiDomain/apis/$servicetype;version=0;realm=$realm/searches other URLs are resolved via HATEOAS!
    * For testing purposes, it was required to change the "App Transport Security Settings" of the example apps (see Info.plist's keypath "NSAppTransportSecurity/NSAllowsArbitraryLoads") to allow arbitrary loads ignoring SSL certificates. Please notice, that this may not be acceptable for productive code.
       
* Dependencies:
    * The framework PlatformTools provides some additional mixed functionality, which is shared among the projects. The super project is self contained, so no 3rd party dependencies are required.
    
* Running the examples:
    * => All apps can be either started with command line arguments or those arguments can be specified in the file ~/Arguments.json. An example of the file Arguemnts.json can be found in the super-project's folder "resources".    
        * When starting the apps on a terminal, make sure you have specified correct command line arguments: open -a __Example.app__ --args _apidomain_ _[servicetype]_ _[realm]_ _username_ _password_ '_[searchexpression]_'
        * If specified in ~/Arguments.json, the parameter names need to be written in all lower case. Every project provides an example argument file to be used for its example.
        * If correct command line arguments are specified, those override reading from the arguments file.
    * The BrowseFolderStructure example expects embedded item data in order to work correctly:
        * open -a BrowseFolderStructure.app --args _apidomain_ _servicetype_ _realm_ _username_ _password_
        * Example: open -a BrowseFolderStructure.app --args upstream avid.mam.assets.access BEEF Administrator ABRAXAS
        * Alternatively provide the arguments in the file ~/Arguments.json and start the app by double-clicking its icon.
        * GUI: Clicking the "Connect" button initializes the treeview with the specified services and allows exploration of the locations structure.

    * The SimpleSearch example awaits the searchexpression in single quotes as last argument:
        * open -a SimpleSearch.app --args _apidomain_ _servicetype_ _realm_ _username_ _password_ '_searchexpression_'
        * Example: open -a SimpleSearch.app --args upstream avid.mam.assets.access BEEF Administrator ABRAXAS "'*'"
        * Alternatively provide the arguments in the file ~/Arguments.json and start the app by double-clicking its icon.
        * GUI: Clicking the "Start" button starts the configured simple search against the specified services and shows its results in a textview.

    * Optionally, e.g. for debugging purposes, inspection of HTTP(S) traffic via a proxy (like Charles (a commercial product) or Burp Suite free) can be enabled by activating a "Secure Web Proxy (HTTPS)" in macOS'
      "System Preferences"/"Network"/"Network Interface"/"Proxies". - Then all HTTP(S) traffic will be recorded in the history of those proxies.
        * !!Mind to deactivate the proxy, in macOS' "Network" preferences after you're done with it! It will block your network traffic !!
        * Notice, that using a proxy can reduce the performance of HTTP requests.
        * Notice also, that having set proxy options as shown above while *no proxy* is configured can reduce the performance of HTTP requests by an order of magnitude!
