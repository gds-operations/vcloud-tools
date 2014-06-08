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

vCloud Tools is based around [fog](http://fog.io/). To use it you'll need to give it credentials that allow it to talk to a vCloud Director environment.

1. Create a '.fog' file in your home directory.
   For example:

    ```yaml
      test_credentials:
        vcloud_director_host: 'host.api.example.com'
        vcloud_director_username: 'username@org_name'
        vcloud_director_password: ''
    ```

2. Obtain a session token. First, curl the API:

    ```bash
    curl -D- -d '' \
      -H 'Accept: application/*+xml;version=5.1' -u '<username>@<org_name>' \
        https://<host.api.example.com>/api/sessions
    ```
   This will prompt for your password.
   From the headers returned, the value of the `x-vcloud-authorization` header is your session token, and this will be valid for 30 minutes idle - any activity will extend its life by another 30 minutes.

3. Specify your credentials and session token at the beginning of the command. For example:

    ```bash
    FOG_CREDENTIAL=test_credentials \
      FOG_VCLOUD_TOKEN=AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF= \
        vcloud-launch node.yaml
    ```
   You may find it easier to export one or both of the values as environment variables.

   **NB** It is also possible to sidestep the need for the session token by saving your password in the fog file. This is **not recommended**.
