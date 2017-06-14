# frozen_string_literal: true

require "erb"
require "fileutils"
require "yaml"

require "spout/helpers/subject_loader"
require "spout/models/coverage_result"
require "spout/helpers/number_helper"
require "spout/helpers/config_reader"
require "spout/helpers/array_statistics"

module Spout
  module Commands
    # Generate a coverage report for the data dictionary.
    class Coverage
      include Spout::Helpers::NumberHelper

      def initialize(standard_version, argv)
        @standard_version = standard_version
        @console = !argv.delete("--console").nil?
        @variable_files = Dir.glob("variables/**/*.json")
        @valid_ids = []
        @number_of_rows = nil
        @config = Spout::Helpers::ConfigReader.new
        @subject_loader = Spout::Helpers::SubjectLoader.new(
          @variable_files, @valid_ids, @standard_version, @number_of_rows, @config.visit
        )
        @subject_loader.load_subjects_from_csvs_part_one! # Not Part Two which is essentially cleaning the data
        @subjects = @subject_loader.subjects
        run_coverage_report!
      end

      def run_coverage_report!
        puts "Generating: index.html\n\n"
        @matching_results = []
        @subject_loader.all_methods.each do |method, csv_files|
          scr = Spout::Models::CoverageResult.new(method, @subjects.collect(&method.to_sym).compact_empty.uniq)
          @matching_results << [csv_files, method, scr]
        end
        variable_ids = Dir.glob("variables/**/*.json").collect { |file| file.gsub(%r{^(.*)/|\.json$}, "").downcase }
        @extra_variable_ids = (variable_ids - @subject_loader.all_methods.keys).sort
        @subject_loader.load_variable_domains!
        domain_ids = Dir.glob("domains/**/*.json").collect { |file| file.gsub(%r{^(.*)/|\.json$}, "").downcase }
        @extra_domain_ids = (domain_ids - @subject_loader.all_domains).sort
        @matching_results.sort! do |a, b|
          [b[2].number_of_errors, a[0].to_s, a[1].to_s] <=> [a[2].number_of_errors, b[0].to_s, b[1].to_s]
        end
        @coverage_results = []
        @subject_loader.csv_files.each do |csv_file|
          total_column_count = @matching_results.select { |mr| mr[0].include?(csv_file) }.count
          mapped_column_count = @matching_results
                                .select { |mr| mr[0].include?(csv_file) && mr[2].number_of_errors.zero? }.count
          @coverage_results << [csv_file, total_column_count, mapped_column_count]
        end
        coverage_folder = File.join(Dir.pwd, "coverage")
        FileUtils.mkpath coverage_folder
        coverage_file = File.join(coverage_folder, "index.html")
        File.open(coverage_file, "w+") do |file|
          erb_location = File.join(File.dirname(__FILE__), "../views/index.html.erb")
          file.puts ERB.new(File.read(erb_location)).result(binding)
        end
        unless @console
          open_command = "open" unless RUBY_PLATFORM.match(/darwin/).nil?
          open_command = "start" unless RUBY_PLATFORM.match(/mingw/).nil?
          system "#{open_command} #{coverage_file}" if %w(start open).include?(open_command)
        end
        puts "#{coverage_file}\n\n"
      end
    end
  end
end
