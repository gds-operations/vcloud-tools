require 'spec_helper'

module Vcloud
  describe Launch do
    before(:each) do
      config_loader = double(:config_loader)
      expect(Vcloud::ConfigLoader).to receive(:new).and_return(config_loader)
      @successful_app_1 = {
          :name => "successful app 1",
          :vdc_name => "Test Vdc",
          :catalog => "default",
          :catalog_item => "ubuntu-precise"
      }
      @fake_failing_app = {
          :name => "fake failing app",
          :vdc_name => "wrong vdc",
          :catalog => "default",
          :catalog_item => "ubuntu-precise"
      }
      @successful_app_2 = {
          :name => "successful app 2",
          :vdc_name => "Test Vdc",
          :catalog => "default",
          :catalog_item => "ubuntu-precise"
      }
      expect(config_loader).to receive(:load_config).with('input_config_yaml')
                               .and_return({:vapps => [@successful_app_1, @fake_failing_app, @successful_app_2]})
    end

    it "should stop on failure by default" do
      expect(VappOrchestrator).to receive(:provision).with(@successful_app_1).and_return(double(:vapp, :power_on => true))
      expect(VappOrchestrator).to receive(:provision).with(@fake_failing_app).and_raise(RuntimeError.new('failed to find vdc'))
      expect(VappOrchestrator).not_to receive(:provision).with(@successful_app_2)

      cli_options = {}
      Launch.new.run('input_config_yaml', cli_options)
    end

    it "should continue on error if cli option continue-on-error is set" do
      expect(VappOrchestrator).to receive(:provision).with(@successful_app_1).and_return(double(:vapp, :power_on => true))
      expect(VappOrchestrator).to receive(:provision).with(@fake_failing_app).and_raise(RuntimeError.new('failed to find vdc'))
      expect(VappOrchestrator).to receive(:provision).with(@successful_app_2).and_return(double(:vapp, :power_on => true))

      cli_options = {"continue-on-error" => true}
      Launch.new.run('input_config_yaml', cli_options)
    end
  end
end
