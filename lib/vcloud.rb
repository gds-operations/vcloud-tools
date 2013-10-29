require 'vcloud/version'
require 'vcloud/provisioner'


module VCloud
  def self.logger
   @logger ||= Logger.new(STDOUT)
  end
end
