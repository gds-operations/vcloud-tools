Vcloud-tools guide
============

A collection of tools that support automation of VMWare VCloud Director

## [Vcloud Provision][vcloud-provision]
A tool that takes a YAML configuration file describing a vDC, and provisions
the vApps and VMs contained within.


Usage:

    bundle exec bin/vcloud-provision {config_file}

Example configuration files can be located in:

    spec/data/*.yaml

Supports:

* Configuration of multiple vApps/VMs with:
  * multiple NICs
  * custom CPU and memory size
  * multiple additional disks
  * custom VM metadata
* Basic idempotent operation - already configured vApps are skipped.
    
Limitations:

* Source vApp Template must contain a single VM. This is the recommended 'simple' 
  method of vApp creation. Complex multi-VM vApps are not supported.
* Org vDC Networks must be precreated.
* IP addresses are assigned manually (recommended) or via DHCP. VM IP pools are
  not supported.
* Only a single source vApp template is possible at the moment. This requires
  VMware Tools installed.
* Configuration file currently does not support sensible defaults for vApps/VMs, making the configuration very verbose and repetitive. This will be fixed in the next release.
* The configuration currently describes a single vDC. This is expected to change to describe a complete Org.





## [Vcloud Walker][vcloudwalker]
A tool that reports on the current state of an environment

## [Configure edgegateway services][edgegateway]
Examples of fog usage to configure Edge Gateway Services

## [Tag search][tag_search]
A tool that will perform operations on a set of Vapps that match the given tags.

####Troubleshooting

To troubleshoot fog related issues, set environment variables DEBUG or EXCON_DEBUG.
For more details see: http://fog.io/about/getting_started.html#debugging.

[vcloudwalker]: https://github.com/alphagov/vcloud-walker
[edgegateway]: docs/edgegateway.md
[tag_search]: docs/tag_search.md




