require_relative 'vcloud/version'
require_relative 'vcloud/provisioner'


module VCloud
  def self.logger
   @logger ||= Logger.new(STDOUT)
  end
end
