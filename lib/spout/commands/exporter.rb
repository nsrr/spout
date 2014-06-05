require 'csv'
require 'json'
require 'fileutils'
require 'colorize'

module Spout
  module Commands
    class Exporter
      def initialize(standard_version, argv)
        @csv_file = argv[1].to_s
        @standard_version = standard_version
        expanded_export!
      end

      private

      def expanded_export!
        folder = "dd/#{@standard_version}"
        puts "      create".colorize( :green ) + "  #{folder}"
        FileUtils.mkpath folder

        variables_export_file = "variables.csv"
        puts "      export".colorize( :blue ) + "  #{folder}/#{variables_export_file}"
        CSV.open("#{folder}/#{variables_export_file}", "wb") do |csv|
          keys = %w(id display_name description type units domain labels calculation)
          csv << ['folder'] + keys
          Dir.glob("variables/**/*.json").sort.each do |file|
            if json = JSON.parse(File.read(file)) rescue false
              variable_folder = variable_folder_path(file)
              csv << [variable_folder] + keys.collect{|key| json[key].kind_of?(Array) ? json[key].join(';') : json[key].to_s}
            end
          end
        end
        domains_export_file = "domains.csv"
        puts "      export".colorize( :blue ) + "  #{folder}/#{domains_export_file}"
        CSV.open("#{folder}/#{domains_export_file}", "wb") do |csv|
          keys = %w(value display_name description)
          csv << ['folder', 'domain_id'] + keys
          Dir.glob("domains/**/*.json").sort.each do |file|
            if json = JSON.parse(File.read(file)) rescue false
              domain_folder = domain_folder_path(file)
              domain_name = extract_domain_name(file)
              json.each do |hash|
                csv << [domain_folder, domain_name] + keys.collect{|key| hash[key]}
              end
            end
          end
        end
      end

      def extract_domain_name(file)
        file.gsub(/domains\//, '').split('/').last.to_s.gsub(/.json/, '')
      end

      def domain_folder_path(file)
        file.gsub(/domains\//, '').split('/')[0..-2].join('/')
      end

      def variable_folder_path(file)
        file.gsub(/variables\//, '').split('/')[0..-2].join('/')
      end

    end
  end
end
