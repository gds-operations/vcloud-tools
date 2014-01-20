require 'vcloud'

module Vcloud
  class Query

    attr_reader :type
    attr_reader :options

    def initialize(type=nil, options={})
      @type = type
      @options = options
      @options[:output_format] ||= 'tsv'
      Fog.mock! if ENV['FOG_MOCK'] || options[:mock]
      @fsi = Vcloud::Fog::ServiceInterface.new
    end

    def filter
      options[:filter]
    end

    def output_format
      options[:output_format]
    end

    def fields
      options[:fields]
    end

    def run()
      if @type.nil?
        output_potential_query_types
      else
        output_query_results
      end
    end

    def get_all_results
      results = []
      (1..get_num_pages).each do |page|
        results += get_results_page(page) || []
      end
      results
    end

    private

    def get_num_pages
      body = @fsi.get_execute_query(type=@type, @options)
      last_page = body[:lastPage] || 1
      raise "Invalid lastPage (#{last_page}) in query results" unless last_page.is_a? Integer
      return last_page.to_i
    end

    def get_results_page(page)
      raise "Must supply a page number" if page.nil?

      begin
        body = @fsi.get_execute_query(type=@type, @options.merge({:page=>page}))
        pp body if @options[:debug]
      rescue ::Fog::Compute::VcloudDirector::BadRequest, ::Fog::Compute::VcloudDirector::Forbidden => e
        raise "Access denied: #{e.message}"
      end

      records = body.keys.detect {|key| key.to_s =~ /Record|Reference$/}
      body[records] = [body[records]] if body[records].is_a?(Hash)
      return nil if body[records].nil? || body[records].empty?
      body[records]

    end

    def output_query_results
      results = get_all_results
      output_header(results)
      output_results(results)
    end

    def output_potential_query_types

      query_list = @fsi.get_execute_query
      queries = {}
      type_width = 0
      query_list[:Link].select do |link|
        link[:rel] == 'down'
      end.map do |link|
        href = Nokogiri::XML.fragment(link[:href])
        query = CGI.parse(URI.parse(href.text).query)
        [query['type'].first, query['format'].first]
      end.each do |type, format|
        queries[type] ||= []
        queries[type] << format
        type_width = [type_width, type.size].max
      end
      queries.keys.sort.each do |type|
        puts "%-#{type_width}s %s" % [type, queries[type].sort.join(',')]
      end

    end

    def output_header(results)
      return if results.size == 0
      case @options[:output_format]
      when 'csv'
        csv_string = CSV.generate do |csv|
          csv << results.first.keys
        end
        puts csv_string
      when 'tsv'
        puts results.first.keys.join("\t")
      end
    end

    def output_results(results)
      return if results.size == 0

      case @options[:output_format]
      when 'yaml'
        puts YAML.dump(results)
      when 'csv'
        csv_string = CSV.generate do |csv|
          results.each do |record|
            csv << record.values
          end
        end
        puts csv_string
      when 'tsv'
        puts results.first.keys.join("\t") if @options[:page] == 1
        results.each do |record|
          puts record.values.join("\t")
        end
      else
        raise "Unsupported output format #{@options[:output_format]}"
      end

    end

  end
end

