require 'yaml'

require 'spout/helpers/subject_loader'
require 'spout/models/coverage_result'

module Spout
  module Commands
    class Coverage
      def initialize(standard_version)
        @standard_version = standard_version

        @variable_files = []
        @valid_ids = []
        @number_of_rows = nil

        spout_config = YAML.load_file('.spout.yml')
        @visit = (spout_config.kind_of?(Hash) ? spout_config['visit'].to_s.strip : '')

        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, @valid_ids, @standard_version, @number_of_rows, @visit)
        @subject_loader.load_subjects_from_csvs_part_one! # Not Part Two which is essentially cleaning the data
        @subjects = @subject_loader.subjects

        run_coverage_report!
      end

      def run_coverage_report!
        choice_variables = []

        Dir.glob("variables/**/*.json").each do |file|
          if json = JSON.parse(File.read(file)) rescue false
            choice_variables << json['id'] if json['type'] == 'choices'
          end
        end

        @matching_results = []
        csv_names = ['tmp_csv_file.csv']

        all_column_headers = @subjects.size > 0 ? @subjects.first.class.instance_methods(false).select{|k| k != :_visit}.reject{|k| k.to_s[-1] == '='} : []
        all_column_headers.each do |column|
          csv = 'tmp_csv_file.csv'
          scr = Spout::Models::CoverageResult.new(csv, column.to_s, @subjects.collect(&column))
          @matching_results << [ csv, column, scr ]
        end


        @matching_results.sort!{|a,b| [b[2].number_of_errors, a[0].to_s, a[1].to_s] <=> [a[2].number_of_errors, b[0].to_s, b[1].to_s]}

        @coverage_results = []

        csv_names.each do |csv_name|
          total_column_count = @matching_results.select{|mr| mr[0] == csv_name}.count
          mapped_column_count = @matching_results.select{|mr| mr[0] == csv_name and mr[2].number_of_errors == 0}.count
          @coverage_results << [ csv_name, total_column_count, mapped_column_count ]
        end

        coverage_folder = File.join(Dir.pwd, 'coverage')
        FileUtils.mkpath coverage_folder
        coverage_file = File.join(coverage_folder, 'index.html')

        print "\nGenerating: index.html\n\n"

        File.open(coverage_file, 'w+') do |file|
          erb_location = File.join( File.dirname(__FILE__), '../views/index.html.erb' )
          file.puts ERB.new(File.read(erb_location)).result(binding)
        end

        open_command = 'open'  if RUBY_PLATFORM.match(/darwin/) != nil
        open_command = 'start' if RUBY_PLATFORM.match(/mingw/) != nil

        system "#{open_command} #{coverage_file}" if ['start', 'open'].include?(open_command)
        puts "#{coverage_file}\n\n"
      end
    end
  end
end
