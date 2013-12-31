Vcloud-tools guide
============

A collection of tools that support automation of VMWare VCloud Director

## [Vcloud Launch][vcloud-launch]
A tool that takes a YAML configuration file describing a vDC, and provisions
the vApps and VMs contained within.

## [Vcloud Walker][vcloudwalker]
A tool that reports on the current state of an environment

## [Vcloud Query][vcloud-query]
A tool to expose the vCloud Query API.

## [Configure edgegateway services][edgegateway]
Examples of fog usage to configure Edge Gateway Services

## [Tag search][tag_search]
A tool that will perform operations on a set of Vapps that match the given tags.

Required set-up
===============

VCloud-tools is based around [fog].

To use it you need a `.fog` file in your home directory.

For example:

    test:
      vcloud_director_username: 'username@org_name'
      vcloud_director_host: 'my-vcloud-director-api.example.com'
      vcloud_director_password: 'password'

Unfortunately current usage of fog requires the password in this file.

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

Unit tests: `bundle exec rake spec`
Runs the the fastest feedback cycle

Integration tests: `bundle exec rake integration_test`
Not included in the above test runs


You need access to an environment as the integration test actually spins up a
VM. The easiest thing to do is create a local shell script called
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

Then run this before you run the integration test.

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

[vcloudwalker]: https://github.com/alphagov/vcloud-walker
[edgegateway]: docs/edgegateway.md
[tag_search]: docs/tag_search.md
[vcloud-launch]: docs/vcloud-launch.md
[vcloud-query]: docs/vcloud-query.md
[fog]: http://fog.io/
