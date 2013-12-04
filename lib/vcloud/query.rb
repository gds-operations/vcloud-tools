require 'vcloud'

module Vcloud
  class Query

    attr_reader :type
    attr_reader :options

    def initialize(type, options={})
      @type = type
      @options = options
      @options[:output_format] ||= 'tsv'
      @fsi = FogServiceInterface.new
    end

    def run()

      puts "options:" if @options[:debug]
      pp @options if @options[:debug]

      if @type.nil?
        output_potential_query_types
      else
        get_and_output_query_results
      end
    end

    def get_num_pages
      body = @fsi.get_execute_query(type=@type, @options)
      last_page = body[:lastPage] || 1
      raise 'No lastPage in query results.' if last_page.nil?
      raise "Invalid lastPage (#{last_page}) in query results" unless last_page.is_a? Integer
      return last_page.to_i
    end

    def get_results_page(page)
      raise "Must supply a page number" if page.nil?

      begin
        body = @fsi.get_execute_query(type=@type, @options.merge({:page=>page}))
      rescue Fog::Compute::VcloudDirector::BadRequest, Fog::Compute::VcloudDirector::Forbidden => e
        Kernel.abort("#{File.basename($0)}: #{e.message}")
      end

      records = body.keys.detect {|key| key.to_s =~ /Record|Reference$/}
      body[records] = [body[records]] if body[records].is_a?(Hash)
      return nil if body[records].nil? || body[records].empty?
      body[records]

    end

    def get_and_output_query_results
      (1..get_num_pages).each do |page|
        results = get_results_page(page)
        break if results.nil?
        output_header(results) if page == 1
        output_results(results)
      end
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

    private

    def output_header(results)
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

