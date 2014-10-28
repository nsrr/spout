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
require 'spout/models/table'
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

        @stratification_variable = Spout::Models::Variable.find_by_id @config.visit

        if @stratification_variable == nil
          if @config.visit == ''
            puts "The visit variable in .spout.yml can't be blank."
          else
            puts "Could not find the following visit variable: #{@config.visit}"
          end
          return self
        end

        missing_variables = @config.charts.select{|c| Spout::Models::Variable.find_by_id(c['chart']) == nil}
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

        @dictionary_root = Dir.pwd
        @variable_files = Dir.glob(File.join(@dictionary_root, 'variables', '**', '*.json'))

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
          variable = Spout::Models::Variable.new(variable_file, @dictionary_root)

          next unless variable.errors.size == 0
          next unless @valid_ids.include?(variable.id) or @valid_ids.size == 0
          next unless ["numeric", "integer", "choices"].include?(variable.type)
          next unless Spout::Models::Subject.method_defined?(variable.id)

          if @deploy_mode
            print "\r     Graph Generation: " + "#{"% 3d" % ((file_index+1)*100/variable_files_count)}% Uploaded".colorize(:white)
          else
            puts "#{file_index+1} of #{variable_files_count}: #{variable.folder}#{variable.id}"
          end

          @progress[variable.id] ||= {}
          next if (not @deploy_mode and @progress[variable.id]['generated'] == true) or (@deploy_mode and @progress[variable.id]['uploaded'] == true)

          stats = {
            charts: {},
            tables: {}
          }

          @chart_variables.each do |chart_type_hash|
            chart_type = chart_type_hash["chart"]
            chart_title = chart_type_hash["title"].downcase.gsub(' ', '-')

            if chart_type == @config.visit
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil }
              if filtered_subjects.count > 0
                graph = Spout::Models::Graph.new(chart_type, filtered_subjects, variable, nil)
                stats[:charts][chart_title] = graph.to_hash
                table = Spout::Models::Table.new(chart_type, filtered_subjects, variable, nil)
                stats[:tables][chart_title] = table.to_hash
              end
            else
              filtered_subjects = @subjects.select{ |s| s.send(chart_type) != nil }
              if filtered_subjects.collect(&variable.id.to_sym).compact.count > 0
                graph = Spout::Models::Graph.new(chart_type, filtered_subjects, variable, @stratification_variable)
                stats[:charts][chart_title] = graph.to_hash
                stats[:tables][chart_title] = @stratification_variable.domain.options.collect do |option|
                  visit_subjects = filtered_subjects.select{ |s| s._visit == option.value }
                  unknown_subjects = visit_subjects.select{ |s| s.send(variable.id) == nil }
                  table = Spout::Models::Table.new(chart_type, visit_subjects, variable, option.display_name)
                  (visit_subjects.count > 0 && visit_subjects.count != unknown_subjects.count) ? table.to_hash : nil
                end.compact
              end
            end
          end

          chart_json_file = File.join(@graphs_folder, "#{variable.id}.json")
          File.open(chart_json_file, 'w') { |file| file.write( JSON.pretty_generate(stats) + "\n" ) }

          @progress[variable.id]['generated'] = true

          if @deploy_mode and not @progress[variable.id]['uploaded'] == true
            response = send_to_server(chart_json_file)
            if response.kind_of?(Hash) and response['upload'] == 'success'
              @progress[variable.id]['uploaded'] = true
            else
              puts "\nUPLOAD FAILED: ".colorize(:red) + File.basename(chart_json_file)
              @progress[variable.id]['uploaded'] = false
            end
          end

          save_current_progress

        end
      end

      def send_to_server(chart_json_file)
        response = Spout::Helpers::SendFile.post("#{@url}/datasets/#{@slug}/upload_graph.json", chart_json_file, @standard_version, @token)
      end

    end
  end
end
