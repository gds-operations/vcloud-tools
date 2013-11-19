require 'ostruct'

class StubFogInterface

  def name
    'Test vDC 1'
  end

  def vdc_object_by_name(vdc_name)
    vdc = OpenStruct.new
    vdc.name = 'test-vdc-1'
    vdc
  end

  def template
    { :href => '/vappTemplate-12345678-90ab-cdef-0123-4567890abcde' }
  end

  def find_networks(network_names, vdc_name)
    [{
      :name => 'org-vdc-1-net-1',
      :href => '/org-vdc-1-net-1-id',
    }]
  end

  def get_vapp(id)
    { :name => 'test-vapp-1' }
  end

  def vdc(name)
    { }
  end

  def post_instantiate_vapp_template(vdc, template, name, params)
    {
      :href => '/test-vapp-1-id',
      :Children => {
        :Vm => ['bogus vm data']
      }
    }
  end

  def get_vapp_by_vdc_and_name
    { }
  end

  def template(catalog_name, name)
    { :href => '/vappTemplate-12345678-90ab-cdef-0123-4567890abcde' }
  end

end
