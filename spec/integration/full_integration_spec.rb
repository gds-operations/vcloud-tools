require 'spec_helper'

describe Vcloud::Launch do

  context 'provision vapp' do
    it 'should create a vapp' do
      runner = Vcloud::Launch.new
      config = runner.run('spec/integration/support/working.yaml')
      expected_name = "vapp-vcloud-tools-tests"
      actual_name = config[0][:name]
      actual_name.should eq(expected_name)
    end
  end
end
