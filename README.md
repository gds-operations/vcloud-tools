Quick Start
===========
**NB:** This repo depends on [Fog](http://fog.io/)
*The fog gem will be installed as a dependency by bundler.*

- Clone this repo and cd into it.
`git clone git@github.com:alphagov/vcloud-tools.git && cd vcloud-tools`
- Install all the dependencies required:
`bundle install`
- Create a `.fog` file in your home directory.
See [.fog example](examples/.fog-example.fog)
- Test your FOG credentials by installing and running [vcloud-walker](https://github.com/alphagov/vcloud-walker):
```
# Install and run vcloud-walker
gem install vcloud-walker
rbenv rehash
FOG_CREDENTIAL=performance-platform-preview vcloud-walk organization --yaml
```

This should give you a readout of your organization profile.

Vcloud-tools guide
============

A collection of tools that support automation of VMWare VCloud Director

## [Vcloud Launch][vcloud-launch]
A tool that takes a YAML configuration file describing a vDC, and provisions
the vApps and VMs contained within.

## [Vcloud Net Launch][vcloud-net-launch]
A tool that takes a YAML configuration file describing vCloud networks and configures each of them.

## [Vcloud Walker][vcloudwalker]
A gem that reports on the current state of an environment

## [Vcloud Query][vcloudquery]
A tool to expose the vCloud Query API, bundled with the [vCloud Core gem][vcloud-core]

## [vCloud Edge Gateway][edgegateway]
A gem to configure a VMware vCloud Edge Gateway

## [Utils][utils]
Useful tools that are not ready for promotion into bin/ and should be considered low quality and/or in development.

Required set-up
===============

VCloud-tools is based around [fog].

To use it you need a `.fog` file in your home directory.

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

## Other settings

Due to parallel development with the Fog gem there is some jiggery-pokery to run
the tool from source. Our Gemfile uses an env var to guide the installation of fog.
If you do nothing, bundler will use the most recent release of fog (pinned by us).
This might work, but if you want to use recent additions, it might be worth using the
latest fog code; we do. Don't worry, we've made this easy.

Setting `VCLOUD_TOOLS_DEV_FOG_MASTER=true` will fetch
Fog's lastest code, to be used with the vcloud-tools. When developing new features
in conjunction with changes in fog, Setting `VCLOUD_TOOLS_DEV_FOG_LOCAL` allows
development against a local version of Fog before changes have reached the fog
master.

## Troubleshooting

To troubleshoot fog related issues, set environment variables DEBUG or EXCON_DEBUG.
For more details see: http://fog.io/about/getting_started.html#debugging.

## Testing

Default target: `bundle exec rake`
Runs the unit and feature tests (pretty quick right now)

* Unit tests only: `bundle exec rake spec`
* Integration tests ('quick' tests): `bundle exec rake integration:quick`
* Integration tests (all tests - takes 20mins+): `bundle exec rake integration:all`

You need access to a suitable vCloud Director organization to run the
integration tests. It is not necessarily safe to run them against an existing
environment, unless care is taken with the entities being tested.

The easiest thing to do is create a local shell script called
`vcloud_env.sh` and set the contents:

    export FOG\_CREDENTIAL=test
    export VCLOUD\_VDC\_NAME="Name of the VDC"
    export VCLOUD\_CATALOG\_NAME="catalog-name"
    export VCLOUD\_TEMPLATE\_NAME="name-of-template"
    export VCLOUD\_NETWORK1\_NAME="name-of-primary-network"
    export VCLOUD\_NETWORK2\_NAME="name-of-secondary-network"
    export VCLOUD\_NETWORK1\_IP="ip-on-primary-network"
    export VCLOUD\_NETWORK2\_IP="ip-on-secondary-network"
    export VCLOUD\_TEST\_STORAGE\_PROFILE="storage-profile-name"
    export VCLOUD\_EDGE\_GATEWAY="name-of-edge-gateway-in-vdc"

Then run this before you run the integration tests.

### Specific integration tests

#### Storage profile tests

There is an integration test to check storage profile behaviour, but it requires a lot of set-up so it is not called by the rake task. If you wish to run it you need access to an environment that has two VDCs, each one containing a storage profile with the same name. This named storage profile needs to be different from teh default storage profile.

You will need to set the following environment variables:

      export VDC\_NAME\_1="Name of the first vDC"
      export VDC\_NAME\_2="Name of the second vDC"
      export VCLOUD\_CATALOG\_NAME="Catalog name" # Can be the same as above settings if appropriate
      export VCLOUD\_TEMPLATE\_NAME="Template name" # Can be the same as above setting if appropriate
      export VCLOUD\_STORAGE\_PROFILE\_NAME="Storage profile name" # This needs to exist in both vDCs
      export VDC\_1\_STORAGE\_PROFILE\_HREF="Href of the named storage profile in vDC 1"
      export VDC\_2\_STORAGE\_PROFILE\_HREF="Href of the named storage profile in vDC 2"
      export DEFAULT\_STORAGE\_PROFILE\_NAME="Default storage profile name"
      export DEFAULT\_STORAGE\_PROFILE\_HREF="Href of default storage profile"

To run this test: `rspec spec/integration/launcher/storage_profile_integration_test.rb`

#### Edge Gateway tests

    spec/integration_tests/edge_gateway/edge_gateway_service_spec.rb

This test tests a variety of update and diff operations against a live
EdgeGateway. **Do not run this against a live EdgeGateway, as it will zero the
configuration**

The EdgeGateway needs to have at least one external 'uplink' network, and
at least one 'internal' network. These should have IP pools assigned to them,
with at least one available IP address.

You will need to set the following env vars:

    export VCLOUD_EDGE_GATEWAY="<name of edgeGateway>"
    export VCLOUD_NETWORK1_NAME="<name of internal network>"
    export VCLOUD_NETWORK1_IP="<ip address on internal network>"
    export VCLOUD_NETWORK1_ID="<id of internal network>"
    export VCLOUD_PROVIDER_NETWORK_ID="<id of uplink network>"
    export VCLOUD_PROVIDER_NETWORK_IP="<ip address on uplink network>"

The easiest way to get this information is to run vcloud-walk from
https://github.com/alphagov/vcloud-walker:

    vcloud-walk edgegateways

... and look through the returned information for a suitable edgeGateway.

[vcloudwalker]: http://rubygems.org/gems/vcloud-walker
[vcloudquery]: docs/vcloud-query.md
[edgegateway]: http://rubygems.org/gems/vcloud-edge_gateway
[vcloud-launch]: docs/vcloud-launch.md
[vcloud-net-launch]: docs/vcloud-net-launch.md
[vcloud-core]: http://rubygems.org/gems/vcloud-core
[fog]: http://fog.io/
[utils]: utils/README.md
