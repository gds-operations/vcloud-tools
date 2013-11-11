module Vcloud

  attr_reader :name, :catalog_name

  class Template

    def initialize fog_interface, args = {}
      @fog_interface = fog_interface
      @catalog_name  = args[:catalog]
      @name          = args[:catalog_item]
      @catalog_item_entity = nil
    end
    
    def id
      if @catalog_item_entity.nil?
        @catalog_item_entity = @fog_interface.template(@catalog_name, @name)
      end

      if @catalog_item_entity.nil?
        Vcloud.logger.fatal("Could not find template vApp. Cannot continue.")
        exit 2
      end

      fetched_id = nil
      begin
        fetched_id = @catalog_item_entity[:href].split('/').last
      rescue
        # something has gone wrong in our vcloud connection
        Vcloud.logger.warn("Could not retrieve a template entity from vCloud")
        fetched_id = nil
      end

      unless fetched_id =~ /^vappTemplate-[-0-9a-f]+$/ 
        Vcloud.logger.warn("Bogus template id #{fetched_id}")
        fetched_id = nil
      end

      fetched_id

    end

  end

end
