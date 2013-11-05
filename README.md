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

####Required set-up
VCloud-tools is based around (fog)[http://fog.io/].

To use it you need a `.fog` file in your home directory.

For example:

    test:
      vcloud_director_username: 'username@org_name'
      vcloud_director_host: 'api.vcd.portal.skyscapecloud.com'

####Troubleshooting

To troubleshoot fog related issues, set environment variables DEBUG or EXCON_DEBUG.
For more details see: http://fog.io/about/getting_started.html#debugging.

[vcloudwalker]: https://github.com/alphagov/vcloud-walker
[edgegateway]: docs/edgegateway.md
[tag_search]: docs/tag_search.md
[vcloud-launch]: docs/vcloud-launch.md

#### Testing

To run the unit tests: `bundle exec rake spec`

To run the integration tests: `bundle exec rake integration_test`.
You need access to an environment as the integration test actually spins up a
VM. The easiest thing to do is create a local shell script called
`vcloud_env.sh` and set the contents:

    export FOG\_CREDENTIAL=test
    export VCLOUD\_TEST\_VDC="Name of the VDC"
    export VCLOUD\_TEST\_CATALOG="catalog-name"
    export VCLOUD\_TEST\_TEMPLATE="name-of-template"

Then run this before you run the integration test.
