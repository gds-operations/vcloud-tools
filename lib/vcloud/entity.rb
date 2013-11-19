module Vcloud
  class Entity

    def id
      return nil unless @vcloud_attributes && @vcloud_attributes[:href]
      @vcloud_attributes[:href].split('/').last
    end

    #def fog_interface
    #  @fog_interface ||= Vcloud::FogServiceInterface.new
    #end
  end
end