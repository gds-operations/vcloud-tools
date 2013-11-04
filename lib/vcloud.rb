require_relative 'vcloud/version'
require_relative 'vcloud/provision'


module VCloud
  def self.logger
   @logger ||= Logger.new(STDOUT)
  end
end
