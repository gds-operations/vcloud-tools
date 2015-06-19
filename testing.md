---
layout: page
title: Testing
permalink: /testing/
---

## Running integration tests

All the vCloud Tools also have integration tests which run the code against a live environment, spinning up and destroying VMs etc. Please note that this means they take some time to run.

### Prerequisites

- Access to a suitable vCloud Director organisation.

    *NB* It is not safe to run the integration tests against an environment that
    is in use (e.g. production, preview) as many of the tests clear down all
    config at the beginning and/or end to ensure the environment is as the tests
    expect.

- A config file with the settings configured.

    Each of the tools has a template file in the `spec/integration` directory
    called `vcloud_tools_testing_config.yaml.template`. This indicates the
    parameters required to run the integration test for that tool. Copy the
    template file to spec/integration/vcloud_tools_testing_config.yaml and
    update with parameters suitable for your environment.

- The set-up for your testing environment needs to be included in your fog file.

- The tests use the vCloud Tools Tester gem. You do not need to install this, bundler will do this for you.

### To run the tests

To run the tests you need to log in in the same way as you would ordinarily. See [usage](/vcloud-tools/usage/) for more details. Once you have obtained a session token, you can run the integration tests:

````
FOG_CREDENTIAL=test_credential bundle exec rake integration
````

## Writing fog Mocks

Ideally, all requests in [fog](https://github.com/fog/fog) would have Mocks, which would allow us to run our integration tests in Mock mode, taking seconds, rather than minutes. However, many of them do not. This is a quick guide as to how to write Mocks in fog.

If the Mock is not implemented for a particular request, the error when running the test will be `Fog::Errors::MockNotImplemented:` and the stack trace will allow you to trace through our code to find the particular request used.

1. Create a method in the Mock class with the same name as the request itself (which will be in the Real class). This method will live in the same file as its Real equivalent.

2. The first thing in the method must be a fog `Forbidden exception`. This should be thrown if the Mock you wish to use is not present in your Mock data and is the same as the error returned by the vCloud API if an entity does not exist. You can copy the pattern here from another Mock, changing it accordingly. It will be something like:

        unless vm = data[:vms][id]
          raise Fog::Compute::VcloudDirector::Forbidden.new(
            'This operation is denied.'
          )
        end

3. Add the Response object. This will be similar to ones in other Mocks. Make sure the `:status` corresponds to what the request expects.

        Excon::Response.new(
          :status => 202,
          :headers => {'Content-Type' => "#{body[:type]};version=#{api_version}"},
          :body => body
        )

4. Write sample Mock data. The easiest way to figure out what this is is to make a request and use the output from that, replacing the relevant parts with variables and taking care not to commit actual information from your environment. There are a number of helper methods for this, for example `make_href` generates a mock href.
To make a request:

        $ irb
        ENV['FOG_CREDENTIAL']='test_credential'
        require 'fog'
        vcloud = Fog::Compute::VcloudDirector.new
        vcloud.put_memory('vm-1111-2222-11-abced-ab', 2048)


    You can find the VM ID by running `vcloud-query vm` on an existing VM.

You can look at an [example PR on fog that adds Mocks](https://github.com/fog/fog/pull/3044).

### Testing your Mocks

Once you've made a change, run the fog Mock tests:

`FOG_CREDENTIAL=fog_mock FOG_MOCK=true bundle exec shindont +vcloud_director`

Once the Mocks are in a released version of fog, the integration tests can be run in Mock mode, e.g:

`FOG_CREDENTIAL=fog_mock FOG_MOCK=true bundle exec rspec spec/integration/core/vm_spec.rb`

In order to test Mocks you have written before making a PR on fog, you can set an environment variable to run the tests against the fog master branch, or a local copy of fog (e.g. for changes not yet merged to fog master). Details of that are in the Gemfile for each tool.

### How to know which Mocks to add

Adding all the Mocks required for one of our tests is a case of: run the tests, look at the first failure, fix that one thing, then run the tests again. 

Usually the fix will be writing or adjusting a Mock; because our integration tests all run against a real enviornment a test failure in Mock mode is unlikely to be a bug in our code.

When our code uses the model layer (rarely), it can be hard to find out which Mocks are the ones that are unimplemented and are causing the error. The best way we've found to do this is to put a rescue block around where the error is being thrown and then look at the backtrace in a runtime developer console such as irb or [Pry](https://github.com/pry/pry).

