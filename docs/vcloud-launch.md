# Launch vApps and VMs

Usage:

    bundle exec vcloud-launch {config_file}

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
* Configuration file currently does not support sensible defaults for vApps/VMs,
  making the configuration very verbose and repetitive. This will be fixed in the
  next release.
* The configuration currently describes a single vDC. This is expected to change
  to describe a complete Org.
* vCloud has some interesting ideas about the size of potential 'guest customisation 
  scripts' (aka preambles). You may need to use an external minify tool to reduce
  the size, or speak to your provider to up the limit. 2048 bytes seems to be a 
  practical default maximum, though YMMV.

