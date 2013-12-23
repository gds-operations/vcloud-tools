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
          Vcloud::Query.any_instance.stub(:get_all_results).and_return(q_results)
          obj = Vdc.get_by_name('vdc-test-1')
          expect(obj.class).to be(Vcloud::Core::Vdc)
        end

        it "should raise an error if no vDC with that name exists" do
          q_results = [ ]
          Vcloud::Query.any_instance.stub(:get_all_results).and_return(q_results)
          expect{ Vdc.get_by_name('vdc-test-1') }.to raise_exception(RuntimeError)
        end

        it "should raise an error if multiple vDCs with that name exist (NB: prescribes unique vDC names!)" do
          q_results = [
            { :name => 'vdc-test-1', :href => @vapp_id },
            { :name => 'vdc-test-1', :href => '/bogus' },
          ]
          Vcloud::Query.any_instance.stub(:get_all_results).and_return(q_results)
          expect{ Vdc.get_by_name('vdc-test-1') }.to raise_exception(RuntimeError)
        end

      end

    end

  end

end
