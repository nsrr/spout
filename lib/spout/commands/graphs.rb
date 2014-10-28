require 'csv'
require 'fileutils'
require 'rubygems'
require 'json'
require 'yaml'
require 'colorize'

require 'spout/helpers/subject_loader'
require 'spout/helpers/chart_types'
require 'spout/models/variable'
require 'spout/models/graph'
require 'spout/helpers/config_reader'
require 'spout/helpers/send_file'
require 'spout/version'

module Spout
  module Commands
    class Graphs
      def initialize(variables, standard_version, deploy_mode = false, url = '', slug = '', token = '')
        @deploy_mode = deploy_mode
        @url = url
        @standard_version = standard_version
        @slug = slug
        @token = token

        argv = variables

        @clean = (argv.delete('--no-resume') != nil or argv.delete('--clean'))

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
        @graphs_folder = File.join("graphs", @standard_version)
        FileUtils.mkpath @graphs_folder

        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, @valid_ids, @standard_version, @number_of_rows, @config.visit)

        @subject_loader.load_subjects_from_csvs!
        @subjects = @subject_loader.subjects

        load_current_progress

        compute_tables_and_charts

        puts "Took #{Time.now - t} seconds." if @subjects.size > 0 and not @deploy_mode
      end

      def load_current_progress
        @progress_file = File.join(@graphs_folder, ".progress.json")
        @progress = JSON.parse(File.read(@progress_file)) rescue @progress = {}
        @progress = {} if !@progress.kind_of?(Hash) or @clean or @progress['SPOUT_VERSION'] != Spout::VERSION::STRING
        @progress['SPOUT_VERSION'] = Spout::VERSION::STRING
      end

      def save_current_progress
        File.open(@progress_file,"w") do |f|
          f.write(@progress.to_json)
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

          if @deploy_mode
            print "\r     Graph Generation: " + "#{"% 3d" % ((file_index+1)*100/variable_files_count)}% Uploaded".colorize(:white)
          else
            puts "#{file_index+1} of #{variable_files_count}: #{variable_file.gsub(/(^variables\/|\.json$)/, '').gsub('/', ' / ')}"
          end

          @progress[variable_name] ||= {}
          next if (not @deploy_mode and @progress[variable_name]['generated'] == true) or (@deploy_mode and @progress[variable_name]['uploaded'] == true)

          stats = {
            charts: {},
            tables: {}
          }

          variable = Spout::Models::Variable.find_by_id variable_name
          visit = Spout::Models::Variable.find_by_id @config.visit

          @chart_variables.each do |chart_type_hash|
            chart_type = chart_type_hash["chart"]
            chart_title = chart_type_hash["title"].downcase.gsub(' ', '-')

            if chart_type == @config.visit
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil }  # and s.send(variable_name) != nil
              if filtered_subjects.count > 0
                graph = Spout::Models::Graph.new(chart_type, filtered_subjects, variable, nil)
                stats[:charts][chart_title] = graph.to_hash
                stats[:tables][chart_title] = Spout::Helpers::ChartTypes::table_arbitrary(chart_type, filtered_subjects, json, variable_name)
              end
            else
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil } # and s.send(variable_name) != nil
              if filtered_subjects.collect(&variable_name.to_sym).compact.count > 0
                graph = Spout::Models::Graph.new(chart_type, filtered_subjects, variable, visit)
                stats[:charts][chart_title] = graph.to_hash
                stats[:tables][chart_title] = visits.collect do |visit_display_name, visit_value|
                  visit_subjects = filtered_subjects.select{ |s| s._visit == visit_value }
                  unknown_subjects = visit_subjects.select{ |s| s.send(variable_name) == nil }
                  (visit_subjects.count > 0 && visit_subjects.count != unknown_subjects.count) ? Spout::Helpers::ChartTypes::table_arbitrary(chart_type, visit_subjects, json, variable_name, visit_display_name) : nil
                end.compact
              end
            end
          end

          chart_json_file = File.join(@graphs_folder, "#{json['id']}.json")
          File.open(chart_json_file, 'w') { |file| file.write( JSON.pretty_generate(stats) + "\n" ) }

          @progress[variable_name]['generated'] = true

          if @deploy_mode and not @progress[variable_name]['uploaded'] == true
            response = send_to_server(chart_json_file)
            if response.kind_of?(Hash) and response['upload'] == 'success'
              @progress[variable_name]['uploaded'] = true
            else
              puts "\nUPLOAD FAILED: ".colorize(:red) + File.basename(chart_json_file)
              @progress[variable_name]['uploaded'] = false
            end
          end

          save_current_progress

        end
      end

      def send_to_server(chart_json_file)
        response = Spout::Helpers::SendFile.post("#{@url}/datasets/#{@slug}/upload_graph.json", chart_json_file, @standard_version, @token)
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
