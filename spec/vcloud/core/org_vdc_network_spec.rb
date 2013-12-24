require 'spec_helper'

module Vcloud
  module Core
    describe OrgVdcNetwork do

      before (:each) do
        @vdc_id    = '12345678-1234-1234-1234-000000111111'
        @edgegw_id = '12345678-1234-1234-1234-000000222222'
        @net_id    = '12345678-1234-1234-1234-000000333333'
        @net_name  = 'net-test-1'
        @mock_fog_interface = StubFogInterface.new
        Vcloud::Fog::ServiceInterface.stub(:new).and_return(@mock_fog_interface)
        Vcloud::Core::Vdc.any_instance.stub(:id).and_return(@vdc_id)
      end

      context "Class public interface" do
        it { OrgVdcNetwork.should respond_to(:get_by_name) }
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
          expect{ OrgVdcNetwork.get_by_name(@net_name) }.to raise_exception(RuntimeError, "found multiple orgVdcNetwork with name net-test-1!")
        end

      end

      context "#delete" do
        it "should call down to Fog::ServiceInterface.delete_network with the correct id" do
          @mock_fog_interface.should_receive(:delete_network).with(@net_id)
          OrgVdcNetwork.new(@net_id).delete
        end
      end

    end

  end
end
