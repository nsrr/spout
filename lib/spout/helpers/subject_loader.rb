# frozen_string_literal: true

require "json"

require "spout/helpers/csv_reader"
require "spout/helpers/semantic"
require "spout/models/subject"
require "spout/models/empty"

module Spout
  module Helpers
    class SubjectLoader
      attr_accessor :subjects
      attr_reader :all_methods, :all_domains, :csv_files, :csv_directory

      def initialize(variable_files, valid_ids, standard_version, number_of_rows, visit)
        @subjects = []
        @variable_files = variable_files
        @valid_ids = valid_ids
        @standard_version = standard_version
        @number_of_rows = number_of_rows
        @visit = visit
        @all_methods = {}
        @all_domains = []
        @csv_files = []
        @csv_directory = ""
      end

      def load_subjects_from_csvs!
        load_subjects_from_csvs_part_one!
        load_subjects_from_csvs_part_two!
      end

      def load_subjects_from_csvs_part_one!
        @subjects = []

        available_folders = (Dir.exist?("csvs") ? Dir.entries("csvs").select { |e| File.directory? File.join("csvs", e) }.reject { |e| [".", ".."].include?(e) }.sort : [])

        @semantic = Spout::Helpers::Semantic.new(@standard_version, available_folders)

        @csv_directory = @semantic.selected_folder

        csv_root = File.join("csvs", @csv_directory)
        @csv_files = Dir.glob("#{csv_root}/**/*.csv").sort

        if @csv_directory != @standard_version
          puts "\n#{@csv_files.size == 0 ? 'No CSVs found' : 'Parsing files' } in " + "#{csv_root}".white + " for dictionary version " + @standard_version.to_s.green + "\n"
        else
          puts "\n#{@csv_files.size == 0 ? 'No CSVs found' : 'Parsing files' } in " + "#{csv_root}".white + "\n"
        end

        last_folder = nil
        @csv_files.each do |csv_file|
          relative_path = csv_file.gsub(%r{^#{csv_root}}, "")
          current_file = File.basename(relative_path)
          current_folder = relative_path.gsub(/#{current_file}$/, "")
          count = 1 # Includes counting the header row
          puts "  #{current_folder}".white if current_folder.to_s != "" && current_folder != last_folder
          print "    #{current_file}"
          last_folder = current_folder

          Spout::Helpers::CSVReader.read_csv(csv_file) do |row|
            count += 1
            print "\r    #{current_file} " + "##{count}".yellow if (count % 10 == 0)
            @subjects << Spout::Models::Subject.create do |t|
              t._visit = row[@visit]
              t._csv = File.basename(csv_file)

              row.each_with_index do |(key, value), index|
                method = key.to_s.downcase.strip
                if method == ""
                  puts "\nSkipping column #{index + 1} due to blank header.".red if count == 2
                  next
                end
                next unless @valid_ids.include?(method) || @valid_ids.size == 0
                unless t.respond_to?(method) && t.respond_to?("#{method}=")
                  t.class.send(:define_method, "#{method}") { instance_variable_get("@#{method}") }
                  t.class.send(:define_method, "#{method}=") { |v| instance_variable_set("@#{method}", v) }
                end
                @all_methods[method] ||= []
                @all_methods[method] = @all_methods[method] | [csv_file]
                if value.nil?
                  t.send("#{method}=", Spout::Models::Empty.new)
                else
                  t.send("#{method}=", value)
                end
              end
            end
            # puts "Memory Used: " + (`ps -o rss -p #{$$}`.strip.split.last.to_i / 1024).to_s + " MB" if count % 1000 == 0
            break if !@number_of_rows.nil? && count - 1 >= @number_of_rows
          end

          print "\r    #{current_file} " + "##{count}".green
          puts "\n"
        end
      end

      def load_subjects_from_csvs_part_two!
        variable_count = @variable_files.count
        print "Converting numeric values to floats"
        @variable_files.each_with_index do |variable_file, index|
          print "\rConverting numeric values to floats:#{'% 3d' % ((index + 1) * 100 / variable_count)}%"
          json = JSON.parse(File.read(variable_file)) rescue json = nil
          next unless json
          next unless @valid_ids.include?(json["id"].to_s.downcase) || @valid_ids.size == 0
          next unless %w(numeric integer).include?(json["type"])
          method = json["id"].to_s.downcase
          next unless Spout::Models::Subject.method_defined?(method)

          domain_json = get_domain(json)
          # Make all domain options nil for numerics/integers
          if domain_json
            domain_values = domain_json.collect { |option_hash| option_hash["value"] }
            @subjects.each { |s| domain_values.include?(s.send(method)) ? s.send("#{method}=", nil) : nil }
          end

          @subjects.each { |s| !s.send(method).nil? ? s.send("#{method}=", s.send("#{method}").to_f) : nil }
        end
        puts "\n"
        @subjects
      end

      def load_variable_domains!
        @variable_files.each do |variable_file|
          json = JSON.parse(File.read(variable_file)) rescue json = nil
          next unless json
          next unless json["type"] == "choices" || json["domain"].to_s.downcase.strip != ""
          domain = json["domain"].to_s.downcase
          @all_domains << domain
        end
        @all_domains = @all_domains.compact.uniq.sort
      end

      def get_json(file_name, file_type)
        file = Dir.glob("#{file_type.to_s.downcase}s/**/#{file_name.to_s.downcase}.json", File::FNM_CASEFOLD).first
        JSON.parse(File.read(file))
      rescue
        nil
      end

      def get_variable(variable_name)
        get_json(variable_name, "variable")
      end

      def get_domain(json)
        get_json(json["domain"], "domain")
      end
    end
  end
end
