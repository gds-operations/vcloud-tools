require 'spec_helper'

describe Vcloud::Deprecator do
  let(:mock_logger) { double(:vcloud_logger) }

  it "should print info about supporting multiple vdcs" do
    Vcloud.should_receive(:logger).and_return(mock_logger)

    mock_logger.should_receive(:info).with('Config file format has changed. vDCs now specified as:')
    mock_logger.should_receive(:info).with('  vdcs:')
    mock_logger.should_receive(:info).with('    - name: "vDC 1"')
    mock_logger.should_receive(:info).with('    - name: "vDC 2"')
    mock_logger.should_receive(:info).with('See spec/data/machines.yaml for an example')
    Kernel.should_receive(:exit).once

    Vcloud::Deprecator.single_vdc_support
  end

  it "should print info about mandatory input config file" do
    Vcloud.should_receive(:logger).and_return(mock_logger)
    mock_logger.should_receive(:info).with('Vcloud::Launch.run now needs config_file passed as single argument.')
    mock_logger.should_receive(:info).with('Ideally you should be using the vcloud-launch CLI tool, which now')
    mock_logger.should_receive(:info).with('has a shiny options interface')

    Kernel.should_receive(:exit).once
    Vcloud::Deprecator.mandatory_input_config_file
  end

end
