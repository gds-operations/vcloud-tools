require 'vcloud/version'
require 'vcloud/launch'


module Vcloud
  def self.logger
   @logger ||= Logger.new(STDOUT)
  end
end
