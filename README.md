Vcloud-tools guide
============

A collection of tools that support automation of VMWare VCloud Director

## [Vcloud Launch][vcloud-launch]
A tool that takes a YAML configuration file describing a vDC, and provisions
the vApps and VMs contained within.

## [Vcloud Walker][vcloudwalker]
A tool that reports on the current state of an environment

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
    export VCLOUD\_TEST\_VDC="Name of the VDC"
    export VCLOUD\_TEST\_CATALOG="catalog-name"
    export VCLOUD\_TEST\_TEMPLATE="name-of-template"
    export VCLOUD\_TEST\_NETWORK1="name-of-primary-network"
    export VCLOUD\_TEST\_NETWORK2="name-of-secondary-network"
    export VCLOUD\_TEST\_NETWORK1_IP="ip-on-primary-network"
    export VCLOUD\_TEST\_NETWORK2_IP="ip-on-secondary-network"

Then run this before you run the integration test.


[vcloudwalker]: https://github.com/alphagov/vcloud-walker
[edgegateway]: docs/edgegateway.md
[tag_search]: docs/tag_search.md
[vcloud-launch]: docs/vcloud-launch.md
[fog]: http://fog.io/
