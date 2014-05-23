require 'csv'
require 'fileutils'
require 'rubygems'
require 'json'
require 'yaml'


require 'spout/models/subject'
require 'spout/helpers/array_statistics'
require 'spout/helpers/chart_types'


module Spout
  module Commands
    class Graphs
      def initialize(variables, standard_version)
        @standard_version = standard_version

        spout_config = YAML.load_file('.spout.yml')

        @visit = ''

        if spout_config.kind_of?(Hash)
          @visit = spout_config['visit'].to_s.strip

          chart_variables = if spout_config['charts'].kind_of?(Array)
            spout_config['charts'].collect{|c| c.to_s.strip}.select{|c| c != ''}
          else
            []
          end
        else
          puts "The YAML file needs to be in the following format:"
          puts "visit: visit_variable_name\ncharts:\n  - age_variable_name\n  - gender_variable_name\n  - race_variable_name\n"
          exit
        end

        if Spout::Helpers::ChartTypes::get_json(@visit, 'variable') == nil
          if @visit == ''
            puts "The visit variable in .spout.yml can't be blank."
          else
            puts "Could not find the following visit variable: #{@visit}"
          end
          exit
        end
        missing_variables = chart_variables.select{|c| Spout::Helpers::ChartTypes::get_json(c, 'variable') == nil}
        if missing_variables.count > 0
          puts "Could not find the following chart variable#{'s' unless missing_variables.size == 1}: #{missing_variables.join(', ')}"
          exit
        end

        argv_string = variables.join(',')
        @number_of_rows = nil

        if match_data = argv_string.match(/-rows=(\d*)/)
          @number_of_rows = match_data[1].to_i
          argv_string.gsub!(match_data[0], '')
        end

        @valid_ids = argv_string.split(',').compact.reject{|s| s == ''}

        @chart_lookup = { @visit => "Histogram" }

        chart_variables.each do |chart_variable|
          json = Spout::Helpers::ChartTypes::get_json(chart_variable, 'variable')
          @chart_lookup[chart_variable] = json['display_name']
        end

        @variable_files = Dir.glob('variables/**/*.json')

        t = Time.now
        load_subjects_from_csvs
        compute_tables_and_charts
        puts "Took #{Time.now - t} seconds."
      end

      def load_subjects_from_csvs
        @subjects = []

        FileUtils.mkpath "graphs/#{@standard_version}"
        csv_files = Dir.glob("csvs/#{@standard_version}/*.csv")

        csv_files.each_with_index do |csv_file, index|
          count = 0
          puts "Parsing: #{csv_file}"
          CSV.parse( File.open(csv_file, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true, header_converters: lambda { |h| h.to_s.downcase } ) do |line|

            row = line.to_hash
            count += 1
            puts "Line: #{count}" if (count % 1000 == 0)
            @subjects << Spout::Models::Subject.create do |t|

              t._visit = row[@visit]

              row.each do |key,value|
                unless t.respond_to?(key)
                  t.class.send(:define_method, "#{key}") { instance_variable_get("@#{key}") }
                  t.class.send(:define_method, "#{key}=") { |value| instance_variable_set("@#{key}", value) }
                end

                unless value == nil
                  t.send("#{key}=", value)
                end
              end
            end
            # puts "Memory Used: " + (`ps -o rss -p #{$$}`.strip.split.last.to_i / 1024).to_s + " MB" if count % 1000 == 0
            # break if count >= 1000
            break if @number_of_rows != nil and count >= @number_of_rows
          end
        end

        @variable_files.each do |variable_file|
          json = JSON.parse(File.read(variable_file)) rescue json = nil
          next unless json
          next unless @valid_ids.include?(json["id"].to_s.downcase) or @valid_ids.size == 0
          next unless ["numeric", "integer"].include?(json["type"])
          method  = json['id'].to_s.downcase
          next unless Spout::Models::Subject.method_defined?(method)

          @subjects.each{ |s| s.send(method) != nil ? s.send("#{method}=", s.send("#{method}").to_f) : nil }
        end

      end

      def compute_tables_and_charts
        variable_files_count = @variable_files.count
        @variable_files.each_with_index do |variable_file, file_index|
          json = JSON.parse(File.read(variable_file)) rescue json = nil
          next unless json
          next unless @valid_ids.include?(json["id"].to_s.downcase) or @valid_ids.size == 0
          next unless ["numeric", "integer", "choices"].include?(json["type"])
          variable_name  = json['id'].to_s.downcase
          next unless Spout::Models::Subject.method_defined?(variable_name)

          puts "#{file_index+1} of #{variable_files_count}: #{variable_file.gsub(/(^variables\/|\.json$)/, '').gsub('/', ' / ')}"


          stats = {
            charts: {},
            tables: {}
          }

          chart_types = case json['type'] when 'integer', 'numeric', 'choices'
            @chart_lookup.keys
          else
            []
          end

          chart_types.each do |chart_type|
            if chart_type == @visit
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil }  # and s.send(variable_name) != nil
              if filtered_subjects.count > 0
                stats[:charts][@chart_lookup[chart_type].downcase] = Spout::Helpers::ChartTypes::chart_histogram(chart_type, filtered_subjects, json, variable_name)
                stats[:tables][@chart_lookup[chart_type].downcase] = Spout::Helpers::ChartTypes::table_arbitrary(chart_type, filtered_subjects, json, variable_name)
              end
            else
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil } # and s.send(variable_name) != nil
              if filtered_subjects.count > 0
                stats[:charts][@chart_lookup[chart_type].downcase] = Spout::Helpers::ChartTypes::chart_arbitrary(chart_type, filtered_subjects, json, variable_name, visits)
                stats[:tables][@chart_lookup[chart_type].downcase] = visits.collect do |visit_display_name, visit_value|
                  visit_subjects = filtered_subjects.select{ |s| s._visit == visit_value }
                  unknown_subjects = visit_subjects.select{ |s| s.send(variable_name) == nil }
                  (visit_subjects.count > 0 && visit_subjects.count != unknown_subjects.count) ? Spout::Helpers::ChartTypes::table_arbitrary(chart_type, visit_subjects, json, variable_name, visit_display_name) : nil
                end.compact
              end
            end
          end

          chart_json_file = File.join('graphs', @standard_version, "#{json['id']}.json")
          File.open(chart_json_file, 'w') { |file| file.write( JSON.pretty_generate(stats) + "\n" ) }

        end


      end

      # [["Visit 1", "1"], ["Visit 2", "2"], ["CVD Outcomes", "3"]]
      def visits
        @visits ||= begin
          Spout::Commands::Graphs::domain_array(@visit)
        end
      end

      def self.domain_array(variable_name)
        variable_file = Dir.glob("variables/**/#{variable_name}.json").first
        json = JSON.parse(File.read(variable_file)) rescue json = nil
        if json
          domain_json = Spout::Helpers::ChartTypes::get_domain(json)
          domain_json ? domain_json.collect{|option_hash| [option_hash['display_name'], option_hash['value']]} : []
        else
          []
        end
      end

    end
  end
end
