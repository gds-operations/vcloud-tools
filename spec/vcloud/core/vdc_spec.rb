require 'spec_helper'

module Vcloud
  module Core
    describe Vdc do

      before(:each) do
        @vdc_id = '12345678-1234-1234-1234-000000111232'
        @mock_fog_interface = StubFogInterface.new
        Vcloud::Fog::ServiceInterface.stub(:new).and_return(@mock_fog_interface)
      end

      context "Class public interface" do
        it { Vdc.should respond_to(:get_by_name) }
      end

      context "Instance public interface" do
        subject { Vdc.new(@vdc_id) }
        it { should respond_to(:id) }
        it { should respond_to(:name) }
        it { should respond_to(:href) }
      end

      context "#initialize" do

        it "should be constructable from just an id reference" do
          obj = Vdc.new(@vdc_id)
          expect(obj.class).to be(Vcloud::Core::Vdc)
        end

        it "should store the id specified" do
          obj = Vdc.new(@vdc_id)
          expect(obj.id) == @vdc_id
        end

        it "should raise error if id is not in correct format" do
          bogus_id = '123123-bogus-id-123445'
          expect{ Vdc.new(bogus_id) }.to raise_error("vdc id : #{bogus_id} is not in correct format" )
        end

      end

      context "#get_by_name" do

        it "should return a Vdc object if name exists" do
          q_results = [
            { :name => 'vdc-test-1', :href => @vdc_id }
          ]
          mock_query = double(:query, :get_all_results => q_results)
          Vcloud::Query.should_receive(:new).with('orgVdc', :filter => "name==vdc-test-1").and_return(mock_query)
          obj = Vdc.get_by_name('vdc-test-1')
          expect(obj.class).to be(Vcloud::Core::Vdc)
        end

        it "should raise an error if no vDC with that name exists" do
          q_results = [ ]
          mock_query = double(:query, :get_all_results => q_results)
          Vcloud::Query.should_receive(:new).with('orgVdc', :filter => "name==vdc-test-1").and_return(mock_query)
          expect{ Vdc.get_by_name('vdc-test-1') }.to raise_exception(RuntimeError, "vDc vdc-test-1 not found")
        end

      end

    end

  end

end
