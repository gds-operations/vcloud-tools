---
layout: page
title: Usage
permalink: /usage/
---

## Installation

Add this line to your application's Gemfile:

    gem 'vcloud-tools'

And then execute:

    $ bundle

Or install it directly using:

    $ gem install vcloud-tools

Installing the [vCloud Tools](https://rubygems.org/gems/vcloud-tools) meta-gem will install all of the tools listed above.

## Setting your credentials

The vCloud Tools projects are based around [fog](http://fog.io/). To use it you'll need to give credentials that allow it to talk to a vCloud Director environment.

1. Create a '.fog' file in your home directory. For example:

    ```yaml
    test_credentials:
      vcloud_director_host: 'host.api.example.com'
      vcloud_director_username: 'username@org_name'
      vcloud_director_password: ''
    ```

2. Obtain a session token:

    ```bash
    eval $(FOG_CREDENTIAL=test_credentials vcloud-login)
    ```

  This will prompt for your password and export a `FOG_VCLOUD_TOKEN` environment variable.

3. Specify your credentials at the beginning of the command. For example:

    ```bash
    FOG_CREDENTIAL=test_credentials vcloud-launch node.yaml
    ```
