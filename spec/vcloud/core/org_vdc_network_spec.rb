require 'spec_helper'

module Vcloud
  module Core
    describe OrgVdcNetwork do

      before (:each) do
        @vdc_id    = '12345678-1234-1234-1234-000000111111'
        @edgegw_id = '12345678-1234-1234-1234-000000222222'
        @net_id    = '12345678-1234-1234-1234-000000333333'
        @vdc_name  = 'test-vdc-1'
        @net_name  = 'test-net-1'
        @mock_fog_interface = StubFogInterface.new
        Vcloud::Fog::ServiceInterface.stub(:new).and_return(@mock_fog_interface)
        Vdc.any_instance.stub(:id).and_return(@vdc_id)
        @mock_vdc = double(:vdc, :id => @vdc_id)
        Vdc.stub(:get_by_name).and_return(@mock_vdc)
      end

      context "Class public interface" do
        it { OrgVdcNetwork.should respond_to(:get_by_name) }
        it { OrgVdcNetwork.should respond_to(:provision) }
      end

      context "Object public interface" do
        subject { OrgVdcNetwork.new(@net_id) }
        it { should respond_to(:id) }
        it { should respond_to(:name) }
        it { should respond_to(:href) }
        it { should respond_to(:delete) }
      end

      context "#initialize" do

        it "should be constructable from just an id reference" do
          obj = OrgVdcNetwork.new(@net_id)
          expect(obj.class).to be(Vcloud::Core::OrgVdcNetwork)
        end

        it "should store the id specified" do
          obj = OrgVdcNetwork.new(@net_id)
          expect(obj.id) == @net_id
        end

        it "should raise error if id is not in correct format" do
          bogus_id = '123123-bogus-id-123445'
          expect{ OrgVdcNetwork.new(bogus_id) }.to raise_error("orgVdcNetwork id : #{bogus_id} is not in correct format" )
        end

      end

      context "#get_by_name" do

        it "should return an OrgVdcNetwork object if name exists" do
          q_results = [
            { :name => @net_name, :href => "/#{@net_id}" }
          ]
          mock_query = double(:query, :get_all_results => q_results)
          Vcloud::Query.should_receive(:new).with('orgVdcNetwork', :filter => "name==#{@net_name}").and_return(mock_query)
          obj = OrgVdcNetwork.get_by_name(@net_name)
          expect(obj.class).to be(Vcloud::Core::OrgVdcNetwork)
        end

        it "should return an OrgVdcNetwork object with correct id if name exists" do
          q_results = [
            { :name => @net_name, :href => "/#{@net_id}" }
          ]
          mock_query = double(:query, :get_all_results => q_results)
          Vcloud::Query.should_receive(:new).with('orgVdcNetwork', :filter => "name==#{@net_name}").and_return(mock_query)
          obj = OrgVdcNetwork.get_by_name(@net_name)
          expect(obj.id) == @net_id
        end

        it "should raise an error if no orgVdcNetwork with that name exists" do
          q_results = [ ]
          mock_query = double(:query, :get_all_results => q_results)
          Vcloud::Query.should_receive(:new).with('orgVdcNetwork', :filter => "name==#{@net_name}").and_return(mock_query)
          expect{ OrgVdcNetwork.get_by_name(@net_name) }.to raise_exception(RuntimeError, "orgVdcNetwork #{@net_name} not found")
        end

        it "should raise an error if >1 orgVdcNetwork with that name exists" do
          q_results = [
            { :name => @net_name, :href => "/#{@net_id}" },
            { :name => @net_name, :href => "/bogus" },
          ]
          mock_query = double(:query, :get_all_results => q_results)
          Vcloud::Query.should_receive(:new).with('orgVdcNetwork', :filter => "name==#{@net_name}").and_return(mock_query)
          expect{ OrgVdcNetwork.get_by_name(@net_name) }.to raise_exception(RuntimeError, "found multiple orgVdcNetwork with name #{@net_name}!")
        end

      end

      context "#delete" do
        it "should call down to Fog::ServiceInterface.delete_network with the correct id" do
          @mock_fog_interface.should_receive(:delete_network).with(@net_id)
          OrgVdcNetwork.new(@net_id).delete
        end
      end

      context "#provision" do

        before(:each) do
          @mock_vdc = double(:vdc, :id => @vdc_id, :href => "/#{@vdc_id}", :name => @vdc_name)
          Vdc.stub(:get_by_name).and_return(@mock_vdc)
        end

        context "should fail gracefully on bad input" do

          before(:each) do
            @config = {
              :name => @net_name,
              :vdc_name => @vdc_name,
              :fence_mode => 'isolated'
            }
          end

          it "should fail if :name is not set" do
            @config.delete(:name)
            expect { Vcloud::Core::OrgVdcNetwork.provision(@config) }.to raise_exception(RuntimeError)
          end

          it "should fail if :vdc_name is not set" do
            @config.delete(:vdc_name)
            expect { Vcloud::Core::OrgVdcNetwork.provision(@config) }.to raise_exception(RuntimeError)
          end

          it "should fail if :fence_mode is not set" do
            @config.delete(:fence_mode)
            expect { Vcloud::Core::OrgVdcNetwork.provision(@config) }.to raise_exception(RuntimeError)
          end

          it "should fail if :fence_mode is not 'isolated' or 'natRouted'" do
            @config[:fence_mode] = 'testfail'
            expect { Vcloud::Core::OrgVdcNetwork.provision(@config) }.to raise_exception(RuntimeError)
          end

        end

        context "isolated orgVdcNetwork" do

          before(:each) do
            q_results = [
              { :name => @net_name, :href => "/#{@net_id}" }
            ]
            @mock_net_query = double(:query, :get_all_results => q_results)
            @config = {
              :name => @net_name,
              :vdc_name => @vdc_name,
              :fence_mode => 'isolated'
            }
          end

          it "should create an OrgVdcNetwork with minimal config" do
            expected_vcloud_attrs = {
              :IsShared => false,
              :Configuration => {
                :FenceMode => 'isolated',
                :IpScopes => {
                  :IpScope => {
                    :IsInherited => false,
                    :IsEnabled => true
                  }
                }
              },
            }
            Vcloud.logger.should_receive(:info)
            @mock_fog_interface.should_receive(:post_create_org_vdc_network).
                with(@vdc_id, @config[:name], expected_vcloud_attrs).
                and_return({ :href => "/#{@net_id}" })
            obj = Vcloud::Core::OrgVdcNetwork.provision(@config)
            expect(obj.id) == @net_id
          end

          it "should handle specification of one ip_ranges" do
            @config[:ip_ranges] = [
              { :start_address => '10.53.53.100', :end_address => '10.53.53.110' }
            ]
            expected_vcloud_attrs = {
              :IsShared => false,
              :Configuration => {
                :FenceMode => 'isolated',
                :IpScopes => {
                  :IpScope => {
                    :IsInherited => false,
                    :IsEnabled => true,
                    :IpRanges => [{
                      :IpRange => {:StartAddress => '10.53.53.100', :EndAddress => '10.53.53.110' },
                    }],
                  }
                }
              }
            }
            Vcloud.logger.should_receive(:info)
            @mock_fog_interface.should_receive(:post_create_org_vdc_network).
                with(@vdc_id, @config[:name], expected_vcloud_attrs).
                and_return({ :href => "/#{@net_id}" })
            obj = Vcloud::Core::OrgVdcNetwork.provision(@config)
          end

          it "should handle specification of two ip_ranges" do
            @config[:ip_ranges] = [
              { :start_address => '10.53.53.100', :end_address => '10.53.53.110' },
              { :start_address => '10.53.53.120', :end_address => '10.53.53.130' },
            ]
            expected_vcloud_attrs = {
              :IsShared => false,
              :Configuration => {
                :FenceMode => 'isolated',
                :IpScopes => {
                  :IpScope => {
                    :IsInherited => false,
                    :IsEnabled => true,
                    :IpRanges => [
                      { :IpRange => {:StartAddress => '10.53.53.100', :EndAddress => '10.53.53.110' }},
                      { :IpRange => {:StartAddress => '10.53.53.120', :EndAddress => '10.53.53.130' }},
                    ]
                  }
                }
              },
            }
            Vcloud.logger.should_receive(:info)
            @mock_fog_interface.should_receive(:post_create_org_vdc_network).
                with(@vdc_id, @config[:name], expected_vcloud_attrs).
                and_return({ :href => "/#{@net_id}" })
            obj = Vcloud::Core::OrgVdcNetwork.provision(@config)
          end

        end

        context "natRouted orgVdcNetwork" do

          before(:each) do
            @config = {
              :name => @net_name,
              :vdc_name => @vdc_name,
              :fence_mode => 'natRouted'
            }
          end

          it "should fail if an edge_gateway is not supplied" do
            expect{ Vcloud::Core::OrgVdcNetwork.provision(@config) }.to raise_exception(RuntimeError)
          end

          it "should handle lack of ip_ranges on natRouted networks" do
            @config[:edge_gateway] = 'test gateway'
            mock_edgegw = Vcloud::Core::EdgeGateway.new(@edgegw_id)
            Vcloud::Core::EdgeGateway.stub(:get_by_name).and_return(mock_edgegw)

            expected_vcloud_attrs = {
              :IsShared => false,
              :Configuration => {
                :FenceMode => 'natRouted',
                :IpScopes => {
                  :IpScope => {
                    :IsInherited => false,
                    :IsEnabled => true
                  }
                }
              },
              :EdgeGateway => { :href => "/#{@edgegw_id}" },
            }
            Vcloud.logger.should_receive(:info)
            @mock_fog_interface.should_receive(:post_create_org_vdc_network).
                with(@vdc_id, @config[:name], expected_vcloud_attrs).
                and_return({ :href => "/#{@net_id}" })
            obj = Vcloud::Core::OrgVdcNetwork.provision(@config)
          end

        end

      end

    end
  end
end
