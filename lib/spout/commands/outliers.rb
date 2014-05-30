require 'yaml'

require 'spout/helpers/subject_loader'
require 'spout/models/outlier_result'

module Spout
  module Commands
    class Outliers
      def initialize(standard_version)
        @standard_version = standard_version

        @variable_files = Dir.glob('variables/**/*.json')
        @valid_ids = []
        @number_of_rows = nil

        spout_config = YAML.load_file('.spout.yml')
        @visit = (spout_config.kind_of?(Hash) ? spout_config['visit'].to_s.strip : '')

        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, @valid_ids, @standard_version, @number_of_rows, @visit)
        @subject_loader.load_subjects_from_csvs!
        @subjects = @subject_loader.subjects
      end

      def run_outliers_report!
        @outlier_results = @subject_loader.all_methods.collect do |method, csv_files|
          Spout::Models::OutlierResult.new(@subjects, method, csv_files)
        end

        @outlier_results.sort!{|a,b| [a.weight, a.method] <=> [b.weight, b.method]}

        @csv_files = Dir.glob("csvs/#{@standard_version}/*.csv")
        @overall_results = @csv_files.collect do |csv_file|
          major_outliers = @outlier_results.select{|outlier_result| outlier_result.csv_files.include?(csv_file) and outlier_result.weight == 0 }.count
          minor_outliers = @outlier_results.select{|outlier_result| outlier_result.csv_files.include?(csv_file) and outlier_result.weight == 1 }.count
          total_outliers = major_outliers + minor_outliers
          [ csv_file, major_outliers, minor_outliers, total_outliers ]
        end

        coverage_folder = File.join(Dir.pwd, 'coverage')
        FileUtils.mkpath coverage_folder
        html_file = File.join(coverage_folder, 'outliers.html')

        print "\nGenerating: outliers.html\n\n"

        File.open(html_file, 'w+') do |file|
          erb_location = File.join( File.dirname(__FILE__), '../views/outliers.html.erb' )
          file.puts ERB.new(File.read(erb_location)).result(binding)
        end

        open_command = 'open'  if RUBY_PLATFORM.match(/darwin/) != nil
        open_command = 'start' if RUBY_PLATFORM.match(/mingw/) != nil

        system "#{open_command} #{html_file}" if ['start', 'open'].include?(open_command)
        puts "#{html_file}\n\n"
      end

    end
  end
end
