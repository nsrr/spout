require 'csv'
require 'fileutils'
require 'rubygems'
require 'json'
require 'yaml'

require 'spout/models/variable'
require 'spout/models/graphables'
require 'spout/helpers/subject_loader'
require 'spout/helpers/chart_types'
require 'spout/helpers/config_reader'
require 'spout/helpers/send_file'

module Spout
  module Commands
    class Images

      def initialize(types, variable_ids, sizes, standard_version, argv, deploy_mode = false, url = '', slug = '', token = '', webserver_name = '')
        @deploy_mode = deploy_mode
        @url = url
        @standard_version = standard_version
        @slug = slug
        @token = token
        @webserver_name = webserver_name


        @dictionary_root = Dir.pwd
        @variable_files = Dir.glob(File.join(@dictionary_root, 'variables', '**', '*.json'))
        @standard_version = standard_version
        @pretend = (argv.delete('--pretend') != nil)
        @clean = (argv.delete('--no-resume') != nil or argv.delete('--clean'))
        @sizes = sizes
        @types = types

        @valid_ids = variable_ids

        @number_of_rows = nil

        @config = Spout::Helpers::ConfigReader.new

        t = Time.now
        @images_folder = File.join("images", @standard_version)
        FileUtils.mkpath @images_folder

        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, @valid_ids, @standard_version, @number_of_rows, @config.visit)

        @subject_loader.load_subjects_from_csvs!
        @subjects = @subject_loader.subjects

        load_current_progress

        compute_images
        puts "Took #{Time.now - t} seconds." if @subjects.size > 0 and not @deploy_mode
      end

      def load_current_progress
        @progress_file = File.join(@images_folder, ".progress.json")
        @progress = JSON.parse(File.read(@progress_file)) rescue @progress = {}
        @progress = {} if !@progress.kind_of?(Hash) or @clean or @progress['SPOUT_VERSION'] != Spout::VERSION::STRING
        @progress['SPOUT_VERSION'] = Spout::VERSION::STRING
      end

      def save_current_progress
        File.open(@progress_file,"w") do |f|
          f.write(@progress.to_json)
        end
      end

      def compute_images
        begin
          iterate_through_variables
        ensure
          save_current_progress
        end
      end

      def iterate_through_variables

        options_folder = "images/#{@standard_version}"
        FileUtils.mkpath( options_folder )
        tmp_options_file = File.join( options_folder, 'options.json' )

        chart_variable = Spout::Models::Variable.find_by_id(@config.visit)
        variable_files_count = @variable_files.count

        @variable_files.each_with_index do |variable_file, file_index|
          variable = Spout::Models::Variable.new(variable_file, @dictionary_root)

          next unless variable.errors.size == 0

          next unless @valid_ids.include?(variable.id) or @valid_ids.size == 0
          next unless @types.include?(variable.type) or @types.size == 0
          next unless ["numeric", "integer", "choices"].include?(variable.type)
          next unless Spout::Models::Subject.method_defined?(variable.id)

          if @deploy_mode
            print "\r     Image Generation: " + "#{"% 3d" % ((file_index+1)*100/variable_files_count)}% Uploaded".colorize(:white)
          else
            puts "#{file_index+1} of #{variable_files_count}: #{variable.folder}#{variable.id}"
          end

          @progress[variable.id] ||= {}
          @progress[variable.id]['uploaded'] ||= []

          next if (not @deploy_mode and @progress[variable.id]['generated'] == true) or (@deploy_mode and @progress[variable.id]['uploaded'].include?(@webserver_name))

          filtered_subjects = @subjects.select{ |s| s.send(@config.visit) != nil }

          graph = Spout::Models::Graphables.for(variable, chart_variable, nil, filtered_subjects)

          if graph.valid?
            File.open(tmp_options_file, "w") do |outfile|
              outfile.puts <<-eos
                {
                  "credits": {
                    "enabled": false
                  },
                  "chart": {
                    "type": "column"
                  },
                  "title": {
                    "text": ""
                  },
                  "xAxis": {
                    "categories": #{graph.categories.to_json}
                  },
                  "yAxis": {
                    "title": {
                      "text": #{graph.units.to_json}
                    }
                  },
                  "plotOptions": {
                    "column": {
                      "pointPadding": 0.2,
                      "borderWidth": 0,
                      "stacking": #{graph.stacking.to_json}
                    }
                  },
                  "series": #{graph.series.to_json}
                }
              eos
            end
            run_phantom_js(variable, "#{variable.id}-lg.png", 600, tmp_options_file) if @sizes.size == 0 or @sizes.include?('lg')
            run_phantom_js(variable, "#{variable.id}.png",     75, tmp_options_file) if @sizes.size == 0 or @sizes.include?('sm')

            @progress[variable.id]['uploaded'] << @webserver_name if @deploy_mode and @progress[variable.id]['upload_failed'] != true
            @progress[variable.id].delete('uploaded_files')
            @progress[variable.id].delete('upload_failed')
          end

        end
        File.delete(tmp_options_file) if File.exist?(tmp_options_file)
      end

      def run_phantom_js(variable, png_name, width, tmp_options_file)
        @progress[variable.id]['generated'] ||= []
        @progress[variable.id]['uploaded_files'] ||= []

        image_path = File.join(Dir.pwd, 'images', @standard_version, png_name)
        directory = File.join( File.dirname(__FILE__), '..', 'support', 'javascripts' )

        open_command = if RUBY_PLATFORM.match(/mingw/) != nil
          'phantomjs.exe'
        else
          'phantomjs'
        end

        phantomjs_command = "#{open_command} #{directory}/highcharts-convert.js -infile #{tmp_options_file} -outfile #{image_path} -scale 2.5 -width #{width} -constr Chart"

        if @pretend
          puts phantomjs_command
        else
          if not @progress[variable.id]['generated'].include?(png_name) or not File.exist?(png_name) or (File.exist?(png_name) and File.size(png_name) == 0)
            `#{phantomjs_command}`
            @progress[variable.id]['generated'] << png_name
          end

          if @deploy_mode and not @progress[variable.id]['uploaded_files'].include?(png_name)
            response = send_to_server(image_path)
            if response.kind_of?(Hash) and response['upload'] == 'success'
              @progress[variable.id]['uploaded_files'] << png_name
            else
              puts "\nUPLOAD FAILED: ".colorize(:red) + File.basename(png_name)
              @progress[variable.id]['upload_failed'] = true
            end
          end
        end
      end

      def send_to_server(file)
        Spout::Helpers::SendFile.post("#{@url}/datasets/#{@slug}/upload_graph.json", file, @standard_version, @token, 'images')
      end

    end
  end
end
