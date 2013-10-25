module Search
  class Vapps
    def search query
      session = Fog::Compute::VcloudDirector.new
      org = session.organizations.get_by_name session.org_name

      eligible_vapps = []

      org.vdcs.each do |vdc|
        vdc.vapps.each do |vapp|
          eligible_vapps << vapp if tag_criteria_met?(vapp, query)
        end
      end
      eligible_vapps
    end

    private

    def tag_criteria_met? vapp, query
      reject_list = query.criteria.reject do |tag_key, tag_value|
        tag = vapp.tags.get_by_id(tag_key)
        tag && tag[:value] == tag_value
      end
      reject_list.empty?
    end

  end
end