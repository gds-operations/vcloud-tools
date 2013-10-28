require_relative '../spec_helper'

describe Provisioner do
  context "provision vapp" do
    Provisioner.new(FogInterface.new(:test)).run(config_file)

  end

end