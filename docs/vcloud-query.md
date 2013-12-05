# Get results from the vCloud Query API

#### Usage:

    vcloud-query --help

#### Supports:

* Returning a list of queriable types (eg vm, vApp, EdgeGateway) from the API
* Displaying all vCloud entities of a given type
* Filtering the results of the query based on common parameters such as:
  * entity name
  * metadata values
  * key entity parameters
* Limiting the output to certain fields (eg: name, vmToolsVersion)
* Returning results in TSV, CSV, and YAML

#### Query Syntax:

Summary of filter query syntax:

    attribute==value                      # == to check equality
    attribute!=value                      # != to check inequality
    attribute=lt=value                    # =lt= less than (=le= for <=)
    attribute=gt=value                    # =gt= greater than (=ge= for >=)
    attribute==value;attribute2==value2   # ; == AND
    attribute==value,attribute2==value2   # , == OR

Parentheses can be used to group sub-queries.

**Do not use spaces in the query**

Entity metadata queries have their own subsyntax incorporating the value types:

    metadata:key1==STRING:value1
    metadata:key1=le=NUMBER:15
    metadata:key1=gt=DATETIME:2012-06-18T12:00:00-05:00

See http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.doc_51/GUID-4FD71B6D-6797-4B8E-B9F0-618F4ACBEFAC.html for details.

#### Examples:

NB: examples assume FOG_CREDENTIAL has been set accordingly.

List all potential queriable types:

  vcloud-query

Get all vApps in an org, in YAML:

  vcloud-query -o yaml vApp

Get all VMs with VMware Tools less than 9282, that are not a vApp Template:

  vcloud-query --filter 'vmToolsVersion=lt=9282;isVAppTemplate==false' vm

