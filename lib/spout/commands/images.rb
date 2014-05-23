require 'csv'
require 'fileutils'
require 'rubygems'
require 'json'

module Spout
  module Commands
    class Images

      def initialize(types, variable_ids, sizes, standard_version)
        @standard_version = standard_version
        total_index_count = Dir.glob("variables/**/*.json").count

        last_completed = 0

        options_folder = "images/#{@standard_version}"
        FileUtils.mkpath( options_folder )
        tmp_options_file = File.join( options_folder, 'options.json' )

        Dir.glob("csvs/#{standard_version}/*.csv").each do |csv_file|
          puts "Working on: #{csv_file}"
          t = Time.now
          csv_table = CSV.table(csv_file, encoding: 'iso-8859-1').by_col!
          puts "Loaded #{csv_file} in #{Time.now - t} seconds."

          total_header_count = csv_table.headers.count
          csv_table.headers.each_with_index do |header, index|
            puts "Column #{ index + 1 } of #{ total_header_count } for #{header} in #{csv_file}"
            if variable_file = Dir.glob("variables/**/#{header.downcase}.json", File::FNM_CASEFOLD).first
              json = JSON.parse(File.read(variable_file)) rescue json = nil
              next unless json
              next unless ["choices", "numeric", "integer"].include?(json["type"])
              next unless types.size == 0 or types.include?(json['type'])
              next unless variable_ids.size == 0 or variable_ids.include?(json['id'].to_s.downcase)

              basename = File.basename(variable_file).gsub(/\.json$/, '').downcase
              col_data = csv_table[header]

              case json["type"] when "choices"
                domain_file = Dir.glob("domains/**/#{json['domain']}.json").first
                domain_json = JSON.parse(File.read(domain_file)) rescue domain_json = nil
                next unless domain_json

                create_pie_chart_options_file(col_data, tmp_options_file, domain_json)
              when 'numeric', 'integer'
                create_line_chart_options_file(col_data, tmp_options_file, json["units"])
              else
                next
              end

              run_phantom_js("#{basename}-lg.png", 600, tmp_options_file) if sizes.size == 0 or sizes.include?('lg')
              run_phantom_js("#{basename}.png",     75, tmp_options_file) if sizes.size == 0 or sizes.include?('sm')
            end
          end
        end
        File.delete(tmp_options_file) if File.exists?(tmp_options_file)
      end

      def graph_values(col_data)
        categories = []

        col_data = col_data.select{|v| !['', 'null'].include?(v.to_s.strip.downcase)}.collect(&:to_f)

        all_integers = false
        all_integers = (col_data.count{|i| i.denominator != 1} == 0)

        minimum = col_data.min || 0
        maximum = col_data.max || 100

        default_max_buckets = 30
        max_buckets = all_integers ? [maximum - minimum + 1, default_max_buckets].min : default_max_buckets
        bucket_size = (maximum - minimum + 1).to_f / max_buckets

        (0..(max_buckets-1)).each do |bucket|
          val_min = (bucket_size * bucket) + minimum
          val_max = bucket_size * (bucket + 1) + minimum
          # Greater or equal to val_min, less than val_max
          # categories << "'#{val_min} to #{val_max}'"
          categories << "#{all_integers || (maximum - minimum) > (default_max_buckets / 2)  ? val_min.round : "%0.02f" % val_min}"
        end

        new_values = []
        (0..max_buckets-1).each do |bucket|
          val_min = (bucket_size * bucket) + minimum
          val_max = bucket_size * (bucket + 1) + minimum
          # Greater or equal to val_min, less than val_max
          new_values << col_data.count{|i| i >= val_min and i < val_max}
        end

        values = []

        values << { name: '', data: new_values, showInLegend: false }

        [ values, categories ]
      end


      def create_pie_chart_options_file(values, options_file, domain_json)

        values.select!{|v| !['', 'null'].include?(v.to_s.strip.downcase) }
        counts = values.group_by{|a| a}.collect{|k,v| [(domain_json.select{|h| h['value'] == k.to_s}.first['display_name'] rescue (k.to_s == '' ? 'NULL' : k)), v.count]}

        total_count = counts.collect(&:last).inject(&:+)

        data = counts.collect{|value, count| [value, (count * 100.0 / total_count)]}

        File.open(options_file, "w") do |outfile|
          outfile.puts <<-eos
            {
              "title": {
                "text": ""
              },

              "credits": {
                  "enabled": false,
              },
              "series": [{
                        "type": "pie",
                        "name": "",
                        "data": #{data.to_json}
              }]
            }
          eos
        end
      end


      def create_line_chart_options_file(values, options_file, units)
        ( series, categories ) = graph_values(values)

        File.open(options_file, "w") do |outfile|
          outfile.puts <<-eos
            {
              "chart": {
                  "type": "areaspline"
              },
              "title": {
                "text": ""
              },
              "credits": {
                  "enabled": false,
              },
              "xAxis": {
                  "categories": #{categories.to_json},
                  "labels": {
                      "step": #{(categories.size.to_f / 12).ceil}
                  },
                  "title": {
                      "text": #{units.to_json}
                  }
              },
              "yAxis": {
                  "maxPadding": 0,
                  "minPadding": 0,
                  "title": {
                    "text": "Count"
                  }
              },
              "series": #{series.to_json}
            }
          eos
        end
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
        # puts phantomjs_command
        `#{phantomjs_command}`
      end

    end
  end
end
