require 'spec_helper'

module Vcloud
  module Core
    describe VappTemplate do

      before(:each) do
        @id = 'vappTemplate-12345678-1234-1234-1234-000000234121'
        @mock_fog_interface = StubFogInterface.new
        Vcloud::Fog::ServiceInterface.stub(:new).and_return(@mock_fog_interface)
        @test_config = {
            :catalog => 'test_catalog',
            :catalog_item => 'test_template'
        }
      end

      context "Class public interface" do
        it { VappTemplate.should respond_to(:get) }
      end

      context "Instance public interface" do
        subject { VappTemplate.new(@id) }
        it { should respond_to(:id) }
        it { should respond_to(:vcloud_attributes) }
        it { should respond_to(:name) }
        it { should respond_to(:href) }
      end

      context "#initialize" do

        it "should be constructable from just an id reference" do
          obj = VappTemplate.new(@id)
          expect(obj.class).to be(Vcloud::Core::VappTemplate)
        end

        it "should store the id specified" do
          obj = VappTemplate.new(@id)
          expect(obj.id) == @id
        end

        it "should raise error if id is not in correct format" do
          bogus_id = '12314124-ede5-4d07-bad5-000000111111'
          expect{ VappTemplate.new(bogus_id) }.to raise_error("vappTemplate id : #{bogus_id} is not in correct format" )
        end

      end


      context '#get' do

        it 'should raise a RuntimeError if there is no template' do
          @mock_fog_interface.should_receive(:template).
            with('test_catalog', 'test_template').and_return(nil)
          expect { VappTemplate.get('test_catalog', 'test_template') }.
            to raise_error('Could not find template vApp')
        end


        it 'should return a valid template object if it exists' do
          test_catalog_item_entity = {
              :href => "/vappTemplate-12345678-90ab-cdef-0123-4567890abcde"
          }
          @mock_fog_interface.should_receive(:template).
            with('test_catalog', 'test_template').
            and_return(test_catalog_item_entity)
          Vcloud::Fog::ServiceInterface.should_receive(:new).
            and_return(@mock_fog_interface)

          test_template = VappTemplate.get('test_catalog', 'test_template')
          test_template.id.should == 'vappTemplate-12345678-90ab-cdef-0123-4567890abcde'
        end

      end

    end
  end
end
