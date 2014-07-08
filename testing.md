---
layout: page
title: Testing
permalink: /testing/
---

## Writing fog mocks

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

4. Write sample Mock data. The easiest way to figure out what this is is to make a request and use the output from that, replacing the relevant parts with variables and taking care not to commit actual information from our environment. There are a number of helper methods for this, for example `make_href` generates a mock href.
To make a request:

        $ irb
        ENV['FOG_CREDENTIAL']='test_credential'
        require 'fog'
        vcloud = Fog::Compute::VcloudDirector.new
        vcloud.put_memory('vm-1111-2222-11-abced-ab', 2048)


    You can find the VM ID by running `vcloud-query vm` on an existing VM.

Once you've made a change, run the fog mock tests:

`FOG_CREDENTIAL=fog_mock FOG_MOCK=true bundle exec shindont +vcloud_director`

Once the mocks are in a released version of fog, the integration tests can be run in mock mode, e.g:

`FOG_CREDENTIAL=fog_mock FOG_MOCK=true bundle exec rspec spec/integration/core/vm_spec.rb`

Adding all the mocks required for one of our tests is a case of: run the tests, look at the first failure, fix that one thing, then run the tests again. 

Usually the fix will be writing or adjusting a mock; because our integration tests all run against a real enviornment a test failure in Mock mode is unlikely to be a bug in our code.

When our code uses the model layer (rarely), it can be hard to find out which mocks are the ones that are unimplemented and are causing the error. The best way I've found to do this is to put a rescue block around where the error is being thrown and then look at the backtrace in a runtime developer console such as irb or [Pry](https://github.com/pry/pry).

In order to test Mocks you have written before making a PR on fog, you can set an environment variable to run the tests against the fog master branch, or a local copy of fog (e.g. for changes not yet merged to fog master). Details of that are in the Gemfile for each tool.
