vCloud Tools
============
A collection of tools for provisioning in vCloud Director.

vCloud Tools is a meta-gem that depends on the tools listed below.

You can install the individual gems you require, or you can include or install vcloud-tools which will give you all of the below.

## vCloud Launcher

A tool that takes a YAML configuration file describing a vDC, and provisions
the vApps and VMs contained within.

( [gem in RubyGems](http://rubygems.org/gems/vcloud-launcher) | [code on GitHub](https://github.com/alphagov/vcloud-launcher) )


## vCloud Net Launcher

A tool that takes a YAML configuration file describing vCloud networks and configures each of them.

( [gem in RubyGems](http://rubygems.org/gems/vcloud-net_launcher) | [code on GitHub](https://github.com/alphagov/vcloud-net_launcher) )

## vCloud Walker
A gem that reports on the current state of an environment.

( [gem in RubyGems](http://rubygems.org/gems/vcloud-walker) | [code on GitHub](https://github.com/alphagov/vcloud-walker) )

## vCloud Edge Gateway
A gem to configure a VMware vCloud Edge Gateway.

( [gem in RubyGems](http://rubygems.org/gems/vcloud-edge_gateway) | [code on GitHub](https://github.com/alphagov/vcloud-edge_gateway) )

## vCloud Core

The gem that handles the interaction with the vCloud API, via [Fog](http://fog.io/).

vCloud Core also comes with command line tool, vCloud Query, which exposes the vCloud Query API.

( [gem in RubyGems](http://rubygems.org/gems/vcloud-core) | [code on GitHub](https://github.com/alphagov/vcloud-core) )

Required set-up
===============

## Credentials

vCloud Tools is based around [fog]. To use it you'll need to give it credentials that allow it to talk to a VMware
environment. Fog offers two ways to do this.

### 1. Create a `.fog` file containing your credentials

To use this method, you need a `.fog` file in your home directory.

For example:

    test:
      vcloud_director_username: 'username@org_name'
      vcloud_director_password: 'password'
      vcloud_director_host: 'host.api.example.com'

Unfortunately current usage of fog requires the password in this file. Multiple sets of credentials can be specified in the fog file, using the following format:

    test:
      vcloud_director_username: 'username@org_name'
      vcloud_director_password: 'password'
      vcloud_director_host: 'host.api.example.com'

    test2:
      vcloud_director_username: 'username@org_name'
      vcloud_director_password: 'password'
      vcloud_director_host: 'host.api.vendor.net'

You can then pass the `FOG_CREDENTIAL` environment variable at the start of your command. The value of the `FOG_CREDENTIAL` environment variable is the name of the credential set in your fog file which you wish to use.  For instance:

    FOG_CREDENTIAL=test2 bundle exec vcloud-launch node.yaml

To understand more about `.fog` files, visit the 'Credentials' section here => http://fog.io/about/getting_started.html.

### 2. Log on externally and supply your session token

You can choose to log on externally by interacting independently with the API and supplying your session token to the
tool by setting the `FOG_VCLOUD_TOKEN` ENV variable. This option reduces the risk footprint by allowing the user to
store their credentials in safe storage. The default token lifetime is '30 minutes idle' - any activity extends the life by another 30 mins.

A basic example of this would be the following:

    curl
       -D-
       -d ''
       -H 'Accept: application/*+xml;version=5.1' -u '<user>@<org>'
       https://host.com/api/sessions

This will prompt for your password.

From the headers returned, select the header below

     x-vcloud-authorization: AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF=

Use token as ENV var FOG_VCLOUD_TOKEN

    FOG_VCLOUD_TOKEN=AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF= bundle exec ...

## Contributing

Contributions are very welcome. Please see the individual tools for contributing guidelines.
