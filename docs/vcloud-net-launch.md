# Launch Org Vdc Networks

Usage:

    bundle exec vcloud-net-launch {config_file}

An example configuration file is located in [examples/vcloud-net-launch][example_yaml]


Supports:

* Configuration of multiple networks
* Supports natRouted and isolated
* Accepts multiple ip address ranges
* Defaults
  * IsShared : false
  * IpScope -> IsEnabled : true
  * IpScope -> IsInherited : false


Limitations

* Not currently reentrant - if the process errors part of the way through, the previously applied network config
will need to be removed from the file before it is corrected and run again.


[example_yaml]: ../examples/vcloud-net-launch/
