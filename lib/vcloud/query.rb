require 'vcloud'

module Vcloud
  class Query

    def initialize
      @options = {}
    end

    def run(type = nil, options = {})

      @options = options

      puts "options:" if @options[:debug]
      pp @options if @options[:debug]

      fsi = FogServiceInterface.new

      if type.nil?

        query_list = fsi.get_execute_query
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

      else

        @options[:page] = 1
        begin
          begin
            response = fsi.get_execute_query(type=type, @options)
          rescue Fog::Compute::VcloudDirector::BadRequest, Fog::Compute::VcloudDirector::Forbidden => e
            Kernel.abort("#{File.basename($0)}: #{e.message}")
          end

          break unless output_response(response)
          @options[:page] = response[:nextPage]

        end until @options[:page].nil?

      end
    end

    def output_response(body)

      records = body.keys.detect {|key| key.to_s =~ /Record|Reference$/}
      return nil if body[records].nil? || body[records].empty?
      body[records] = [body[records]] if body[records].is_a?(Hash)

      case @options[:output_format]
      when 'yaml'
        puts YAML.dump(body)
      when 'raw'
        pp body
      when 'csv'
        csv_string = CSV.generate do |csv|
          if @options[:page] == 1
            csv << body[records].first.keys
          end
          body[records].each do |record|
            csv << record.values
          end
        end
        puts csv_string
      else
        puts body[records].first.keys.join("\t") if @options[:page] == 1
        body[records].each do |record|
          puts record.values.join("\t")
        end
      end

    end

  end
end


