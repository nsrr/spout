require 'csv'
require 'fileutils'
require 'rubygems'
require 'json'
require 'yaml'

require 'spout/helpers/subject_loader'
require 'spout/helpers/chart_types'
require 'spout/helpers/config_reader'

module Spout
  module Commands
    class Graphs
      def initialize(variables, standard_version)
        @standard_version = standard_version

        @config = Spout::Helpers::ConfigReader.new

        if Spout::Helpers::ChartTypes::get_json(@config.visit, 'variable') == nil
          if @config.visit == ''
            puts "The visit variable in .spout.yml can't be blank."
          else
            puts "Could not find the following visit variable: #{@config.visit}"
          end
          return self
        end

        missing_variables = @config.charts.select{|c| Spout::Helpers::ChartTypes::get_json(c['chart'], 'variable') == nil}
        if missing_variables.count > 0
          puts "Could not find the following chart variable#{'s' unless missing_variables.size == 1}: #{missing_variables.join(', ')}"
          return self
        end

        argv_string = variables.join(',')
        @number_of_rows = nil

        if match_data = argv_string.match(/-rows=(\d*)/)
          @number_of_rows = match_data[1].to_i
          argv_string.gsub!(match_data[0], '')
        end

        @valid_ids = argv_string.split(',').compact.reject{|s| s == ''}

        @chart_variables = @config.charts.unshift( { "chart" => @config.visit, "title" => 'Histogram' } )

        @variable_files = Dir.glob('variables/**/*.json')

        t = Time.now
        FileUtils.mkpath "graphs/#{@standard_version}"

        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, @valid_ids, @standard_version, @number_of_rows, @config.visit)

        @subject_loader.load_subjects_from_csvs!
        @subjects = @subject_loader.subjects
        compute_tables_and_charts

        puts "Took #{Time.now - t} seconds."
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

          @chart_variables.each do |chart_type_hash|
            chart_type = chart_type_hash["chart"]
            chart_title = chart_type_hash["title"].downcase.gsub(' ', '-')

            if chart_type == @config.visit
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil }  # and s.send(variable_name) != nil
              if filtered_subjects.count > 0
                stats[:charts][chart_title] = Spout::Helpers::ChartTypes::chart_histogram(chart_type, filtered_subjects, json, variable_name)
                stats[:tables][chart_title] = Spout::Helpers::ChartTypes::table_arbitrary(chart_type, filtered_subjects, json, variable_name)
              end
            else
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil } # and s.send(variable_name) != nil
              if filtered_subjects.collect(&variable_name.to_sym).compact.count > 0
                stats[:charts][chart_title] = Spout::Helpers::ChartTypes::chart_arbitrary(chart_type, filtered_subjects, json, variable_name, visits)
                stats[:tables][chart_title] = visits.collect do |visit_display_name, visit_value|
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
          Spout::Helpers::ChartTypes::domain_array(@config.visit)
        end
      end

    end
  end
end
