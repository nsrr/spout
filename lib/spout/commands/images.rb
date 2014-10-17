require 'csv'
require 'fileutils'
require 'rubygems'
require 'json'
require 'yaml'

require 'spout/helpers/subject_loader'
require 'spout/helpers/chart_types'
require 'spout/helpers/config_reader'
require 'spout/helpers/send_file'

module Spout
  module Commands
    class Images

      def initialize(types, variable_ids, sizes, standard_version, argv, deploy_mode = false, url = '', slug = '', token = '')
        @deploy_mode = deploy_mode
        @url = url
        @standard_version = standard_version
        @slug = slug
        @token = token


        @variable_files = Dir.glob('variables/**/*.json')
        @standard_version = standard_version
        @pretend = (argv.delete('--pretend') != nil)
        @sizes = sizes
        @types = types

        @valid_ids = variable_ids

        @number_of_rows = nil

        @config = Spout::Helpers::ConfigReader.new

        t = Time.now
        FileUtils.mkpath "graphs/#{@standard_version}"

        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, @valid_ids, @standard_version, @number_of_rows, @config.visit)

        @subject_loader.load_subjects_from_csvs!
        @subjects = @subject_loader.subjects

        compute_images
        puts "Took #{Time.now - t} seconds." if @subjects.size > 0 and not @deploy_mode
      end

      def compute_images

        options_folder = "images/#{@standard_version}"
        FileUtils.mkpath( options_folder )
        tmp_options_file = File.join( options_folder, 'options.json' )

        variable_files_count = @variable_files.count
        @variable_files.each_with_index do |variable_file, file_index|
          json = JSON.parse(File.read(variable_file)) rescue json = nil
          next unless json
          next unless @valid_ids.include?(json["id"].to_s.downcase) or @valid_ids.size == 0
          next unless @types.include?(json["type"]) or @types.size == 0
          next unless ["numeric", "integer", "choices"].include?(json["type"])
          variable_name  = json['id'].to_s.downcase
          next unless Spout::Models::Subject.method_defined?(variable_name)

          if @deploy_mode
            print "\r     Image Generation: " + "#{"% 3d" % ((file_index+1)*100/variable_files_count)}% Uploaded".colorize(:white)
          else
            puts "#{file_index+1} of #{variable_files_count}: #{variable_file.gsub(/(^variables\/|\.json$)/, '').gsub('/', ' / ')}"
          end

          filtered_subjects = @subjects.select{ |s| s.send(@config.visit) != nil }

          chart_json = Spout::Helpers::ChartTypes::chart_histogram(@config.visit, filtered_subjects, json, variable_name)

          if chart_json
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
                    "categories": #{chart_json[:categories].to_json}
                  },
                  "yAxis": {
                    "title": {
                      "text": #{chart_json[:units].to_json}
                    }
                  },
                  "plotOptions": {
                    "column": {
                      "pointPadding": 0.2,
                      "borderWidth": 0,
                      "stacking": #{chart_json[:stacking].to_json}
                    }
                  },
                  "series": #{chart_json[:series].to_json}
                }
              eos
            end
            run_phantom_js("#{json['id']}-lg.png", 600, tmp_options_file) if @sizes.size == 0 or @sizes.include?('lg')
            run_phantom_js("#{json['id']}.png",     75, tmp_options_file) if @sizes.size == 0 or @sizes.include?('sm')
          end

        end
        File.delete(tmp_options_file) if File.exist?(tmp_options_file)
      end

      def run_phantom_js(png_name, width, tmp_options_file)
        graph_path = File.join(Dir.pwd, 'images', @standard_version, png_name)
        directory = File.join( File.dirname(__FILE__), '..', 'support', 'javascripts' )

        open_command = if RUBY_PLATFORM.match(/mingw/) != nil
          'phantomjs.exe'
        else
          'phantomjs'
        end

        phantomjs_command = "#{open_command} #{directory}/highcharts-convert.js -infile #{tmp_options_file} -outfile #{graph_path} -scale 2.5 -width #{width} -constr Chart"

        if @pretend
          puts phantomjs_command
        else
          `#{phantomjs_command}`

          send_to_server(graph_path) if @deploy_mode
        end
      end

      def send_to_server(file)
        response = Spout::Helpers::SendFile.post("#{@url}/datasets/#{@slug}/upload_graph.json", file, @standard_version, @token, 'images')
      end

    end
  end
end
