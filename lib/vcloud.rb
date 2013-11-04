require 'vcloud/version'
require 'vcloud/launch'


module VCloud
  def self.logger
   @logger ||= Logger.new(STDOUT)
  end
end
