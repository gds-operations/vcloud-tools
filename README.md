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


## Installation

Add this line to your application's Gemfile:

    gem 'vcloud-tools'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vcloud-tools

Installing vCloud Tools will install all of the tools listed above.

## Credentials

vCloud Tools is based around [fog](http://fog.io/). To use it you'll need to give it credentials that allow it to talk to a vCloud Director environment.

1. Create a '.fog' file in your home directory.

  For example:

      test_credentials:
        vcloud_director_host: 'host.api.example.com'
        vcloud_director_username: 'username@org_name'
        vcloud_director_password: ''

2. Obtain a session token. First, curl the API:

        curl -D- -d '' \
            -H 'Accept: application/*+xml;version=5.1' -u '<username>@<org_name>' \
            https://<host.api.example.com>/api/sessions

  This will prompt for your password.

  From the headers returned, the value of the `x-vcloud-authorization` header is your session token, and this will be valid for 30 minutes idle - any activity will extend its life by another 30 minutes.

3. Specify your credentials and session token at the beginning of the command. For example:

        FOG_CREDENTIAL=test_credentials \
            FOG_VCLOUD_TOKEN=AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF= \
            vcloud-launch node.yaml

  You may find it easier to export one or both of the values as environment variables.

  **NB** It is also possible to sidestep the need for the session token by saving your password in the fog file. This is **not recommended**.

## Contributing

Contributions are very welcome. Please see the individual tools for contributing guidelines.
