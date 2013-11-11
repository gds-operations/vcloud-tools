module Vcloud

  attr_reader :name, :catalog_name

  class Template

    def initialize fog_interface, args = {}
      @fog_interface = fog_interface
      @catalog_name  = args[:catalog]
      @name          = args[:catalog_item]
      @fog_model_template_object = nil
    end
    
    def id
      if @fog_model_template_object.nil?
        @fog_model_template_object = @fog_interface.template(@catalog_name, @name)
      end

      if @fog_model_template_object.nil?
        Vcloud.logger.fatal("Could not find template vApp. Cannot continue.")
        exit 2
      end

      @fog_model_template_object[:href].split('/').last
    end

  end

end
