require 'csv'
require 'fileutils'
require 'rubygems'
require 'json'
require 'yaml'
require 'colorize'

require 'spout/helpers/subject_loader'
require 'spout/helpers/chart_types'
require 'spout/models/variable'
require 'spout/models/graphables'
require 'spout/models/tables'
require 'spout/helpers/config_reader'
require 'spout/helpers/send_file'
require 'spout/helpers/json_request_generic'
require 'spout/version'

module Spout
  module Commands
    class Graphs
      def initialize(argv, standard_version, deploy_mode = false, url = '', slug = '', token = '', webserver_name = '', subjects = nil)
        @deploy_mode = deploy_mode
        @url = url
        @standard_version = standard_version
        @slug = slug
        @token = token
        @webserver_name = webserver_name
        @clean = !(argv.delete('--no-resume').nil? && argv.delete('--clean').nil?)

        @config = Spout::Helpers::ConfigReader.new

        @stratification_variable = Spout::Models::Variable.find_by_id @config.visit

        if @stratification_variable.nil?
          if @config.visit == ''
            puts "The visit variable in .spout.yml can't be blank."
          else
            puts "Could not find the following visit variable: #{@config.visit}"
          end
          return self
        end

        missing_variables = @config.charts.select { |c| Spout::Models::Variable.find_by_id(c['chart']).nil? }
        if missing_variables.count > 0
          puts "Could not find the following chart variable#{'s' unless missing_variables.size == 1}: #{missing_variables.join(', ')}"
          return self
        end

        rows_arg = argv.find { |arg| /^--rows=(\d*)/ =~ arg }
        argv.delete(rows_arg)
        @number_of_rows = rows_arg.gsub(/--rows=/, '').to_i if rows_arg

        @valid_ids = argv.collect { |s| s.to_s.downcase }.compact.reject { |s| s == '' }

        @chart_variables = @config.charts.unshift('chart' => @config.visit, 'title' => 'Histogram')

        @dictionary_root = Dir.pwd
        @variable_files = Dir.glob(File.join(@dictionary_root, 'variables', '**', '*.json'))

        t = Time.now
        @graphs_folder = File.join('graphs', @standard_version)
        FileUtils.mkpath @graphs_folder

        @subjects = if subjects
                      subjects
                    else
                      @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, @valid_ids, @standard_version, @number_of_rows, @config.visit)
                      @subject_loader.load_subjects_from_csvs!
                      @subjects = @subject_loader.subjects
                    end

        load_current_progress

        compute_tables_and_charts

        puts "Took #{Time.now - t} seconds." if @subjects.size > 0 && !@deploy_mode
      end

      def load_current_progress
        @progress_file = File.join(@graphs_folder, '.progress.json')
        @progress = JSON.parse(File.read(@progress_file)) rescue @progress = {}
        @progress = {} if !@progress.is_a?(Hash) || @clean || @progress['SPOUT_VERSION'] != Spout::VERSION::STRING
        @progress['SPOUT_VERSION'] = Spout::VERSION::STRING
      end

      def save_current_progress
        File.open(@progress_file, 'w') do |f|
          f.write(JSON.pretty_generate(@progress) + "\n")
        end
      end

      def compute_tables_and_charts
        begin
          iterate_through_variables
        ensure
          save_current_progress
        end
      end

      def send_to_server(chart_json_file)
        response = Spout::Helpers::SendFile.post("#{@url}/datasets/#{@slug}/upload_graph.json", chart_json_file, @standard_version, @token)
      end

      def iterate_through_variables
        variable_files_count = @variable_files.count
        @variable_files.each_with_index do |variable_file, file_index|
          variable = Spout::Models::Variable.new(variable_file, @dictionary_root)

          next unless variable.errors.size == 0
          next unless @valid_ids.include?(variable.id) || @valid_ids.size == 0
          next unless %w(numeric integer choices).include?(variable.type)
          next unless Spout::Models::Subject.method_defined?(variable.id)

          if @deploy_mode
            print "\r     Graph Generation: " + "#{"% 3d" % ((file_index+1)*100/variable_files_count)}% Uploaded".colorize(:white)
          else
            puts "#{file_index + 1} of #{variable_files_count}: #{variable.folder}#{variable.id}"
          end

          @progress[variable.id] ||= {}
          @progress[variable.id]['uploaded'] ||= []
          next if (!@deploy_mode && @progress[variable.id]['generated'] == true) || (@deploy_mode && @progress[variable.id]['uploaded'].include?(@webserver_name))

          stats = {
            charts: {},
            tables: {}
          }

          @chart_variables.each do |chart_type_hash|
            chart_type = chart_type_hash['chart']
            chart_title = chart_type_hash['title'].downcase.gsub(' ', '-')
            chart_variable = Spout::Models::Variable.find_by_id(chart_type)

            filtered_subjects = @subjects.reject { |s| s.send(chart_type).nil? || s.send(variable.id).nil? }

            next if filtered_subjects.collect(&variable.id.to_sym).compact_empty.count == 0
            if chart_type == @config.visit
              graph = Spout::Models::Graphables.for(variable, chart_variable, nil, filtered_subjects)
              stats[:charts][chart_title] = graph.to_hash
              table = Spout::Models::Tables.for(variable, chart_variable, filtered_subjects, nil, totals: false)
              stats[:tables][chart_title] = table.to_hash
            else
              graph = Spout::Models::Graphables.for(variable, chart_variable, @stratification_variable, filtered_subjects)
              stats[:charts][chart_title] = graph.to_hash
              stats[:tables][chart_title] = @stratification_variable.domain.options.collect do |option|
                visit_subjects = filtered_subjects.select { |s| s._visit == option.value }
                Spout::Models::Tables.for(variable, chart_variable, visit_subjects, option.display_name).to_hash
              end.compact
            end
          end

          chart_json_file = File.join(@graphs_folder, "#{variable.id}.json")
          File.open(chart_json_file, 'w') { |file| file.write(JSON.pretty_generate(stats) + "\n") }
          @progress[variable.id]['generated'] = true

          if @deploy_mode && !@progress[variable.id]['uploaded'].include?(@webserver_name)

            # response = send_to_server(chart_json_file)
            # if response.is_a?(Hash) && response['upload'] == 'success'
            #   @progress[variable.id]['uploaded'] << @webserver_name
            # else
            #   puts "\nUPLOAD FAILED: ".colorize(:red) + File.basename(chart_json_file)
            # end

            values = @subjects.collect(&variable.id.to_sym).compact_empty
            variable.n = values.n
            variable.unknown = values.unknown
            variable.total = values.count
            if %w(numeric integer).include?(variable.type)
              variable.mean = values.mean
              variable.stddev = values.standard_deviation
              variable.median = values.median
              variable.min = values.min
              variable.max = values.max
            end
            send_variable_params_to_server(variable, stats)
          end
        end
      end

      def send_variable_params_to_server(variable, stats)
        params = { auth_token: @token, version: @standard_version,
                   dataset: @slug, variable: variable.deploy_params,
                   domain: (variable.domain ? variable.domain.deploy_params : nil),
                   forms: variable.forms.collect(&:deploy_params) }
        params[:variable][:spout_stats] = stats
        (response, status) = Spout::Helpers::JsonRequestGeneric.post("#{@url}/api/v1/variables/create_or_update.json", params)
        if response.is_a?(Hash) && status.is_a?(Net::HTTPSuccess)
          # puts "response: #{response}".colorize(:blue)
          @progress[variable.id]['uploaded'] << @webserver_name
        else
          puts "\nUPLOAD FAILED: ".colorize(:red) + variable.id
          puts "- Error: #{response.inspect}"
        end
      end
    end
  end
end
