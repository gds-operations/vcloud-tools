require 'spec_helper'

module Vcloud
  module Core
    describe VappTemplate do

    before(:each) do
      @mock_fog_interface = double(:fog_interface)
      @test_config = {
          :catalog => 'test_catalog',
          :catalog_item => 'test_template'
      }
    end

    it 'should raise a RuntimeError if there is no template' do
      @mock_fog_interface.should_receive(:template).with('test_catalog', 'test_template').and_return(nil)
      Vcloud::Fog::ServiceInterface.should_receive(:new).and_return(@mock_fog_interface)

      expect { VappTemplate.get('test_catalog', 'test_template') }.to raise_exception(RuntimeError, 'Could not find template vApp')
    end

    context "id" do
      it 'should return the id of the template' do
        test_catalog_item_entity = {
            :href => "/vappTemplate-12345678-90ab-cdef-0123-4567890abcde"
        }
        @mock_fog_interface.should_receive(:template).with('test_catalog', 'test_template').and_return(test_catalog_item_entity)
        Vcloud::Fog::ServiceInterface.should_receive(:new).and_return(@mock_fog_interface)

        test_template = VappTemplate.get('test_catalog', 'test_template')
        test_template.id.should == 'vappTemplate-12345678-90ab-cdef-0123-4567890abcde'
      end

      it "should raise error if invalid id is found" do
        test_catalog_item_entity = {
            :href => "/#{'vAppTemplate-12345678-90ab-cdef-0123-4567890abcde'}"
        }
        @mock_fog_interface.should_receive(:template).with('test_catalog', 'test_template').and_return(test_catalog_item_entity)
        Vcloud::Fog::ServiceInterface.should_receive(:new).and_return(@mock_fog_interface)

        test_template = VappTemplate.get('test_catalog', 'test_template')
        expect { test_template.id }.to raise_exception(RuntimeError, 'vappTemplate id : vmTemplate-12345678-90ab-cdef-0123-4567890abcde is not in correct format')
      end
    end

    it 'should fail gracefully if id is not of expected form' do
      test_catalog_item_entity = {
          :href => '/1234'
      }
      @mock_fog_interface.should_receive(:template).with('test_catalog', 'test_template').and_return(test_catalog_item_entity)
      Vcloud::Fog::ServiceInterface.should_receive(:new).and_return(@mock_fog_interface)

      test_template = VappTemplate.get('test_catalog', 'test_template')
      expect { test_template.id }.to raise_exception(RuntimeError, 'vappTemplate id : 1234 is not in correct format')
    end

  end
  end
end
