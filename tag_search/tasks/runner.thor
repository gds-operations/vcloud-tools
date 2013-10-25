require File.expand_path("../../vapp_search.rb", __FILE__)

class Runner < Thor
  map "-L" => :list

  VAPP_OPERATIONS = [:power_off, :power_on, :shutdown, :reboot, :suspend]

  desc "vapps", "performs an operation on a set of vapps satisfying certain condition"
  def vapps search_query, operation
    raise "invalid arguments" unless search_query && VAPP_OPERATIONS.include?(operation.to_sym)

    query = TagQuery.new(search_query)
    eligible_vapps = Search::Vapps.new.search(query)
    eligible_vapps.empty? ? (p 'no vapp found with above tags') : perform_operation(eligible_vapps, operation.to_sym)
  end

  private

  def perform_operation(eligible_vapps, operation)
    eligible_vapps.map do |vapp|
      if vapp.send(operation)
        puts "\n successfully executed #{operation} operation on #{vapp.name}"
      else
        puts "\n [ERROR] Failed to execute #{operation} operation on #{vapp.name}"
      end
    end
  end

end

