# frozen_string_literal: true

require 'csv'
require 'json'
require 'fileutils'
require 'colorize'

require 'spout/helpers/config_reader'

module Spout
  module Commands
    # Exports the JSON data dictionary to a CSV format.
    class Exporter
      def initialize(standard_version, argv)
        @quiet = !argv.delete('--quiet').nil?
        @standard_version = standard_version
        @config = Spout::Helpers::ConfigReader.new
        expanded_export!
      end

      private

      def expanded_export!
        folder = "exports/#{@standard_version}"
        puts '      create'.colorize(:green) + "  #{folder}" unless @quiet
        FileUtils.mkpath folder
        generic_export(
          folder,
          'variables',
          %w(
            id display_name description type units domain labels calculation
            commonly_used forms
          )
        )
        generic_export(folder, 'domains', %w(value display_name description), true)
        generic_export(folder, 'forms', %w(id display_name code_book))
      end

      def generic_export(folder, type, keys, include_domain_name = false)
        export_file = export_file_name(type)
        puts '      export'.colorize(:blue) + "  #{folder}/#{export_file}" unless @quiet
        CSV.open("#{folder}/#{export_file}", 'wb') do |csv|
          csv << if include_domain_name
                   %w(folder domain_id) + keys
                 else
                   %w(folder) + keys
                 end
          Dir.glob("#{type}/**/*.json").sort.each do |file|
            json = JSON.parse(File.read(file)) rescue false
            if json
              relative_folder = generic_folder_path(file, type)
              if include_domain_name
                domain_name = extract_domain_name(file)
                json.each do |hash|
                  csv << [relative_folder, domain_name] + keys.collect { |key| hash[key] }
                end
              else
                csv << [relative_folder] + keys.collect do |key|
                  json[key].is_a?(Array) ? json[key].join(';') : json[key].to_s
                end
              end
            end
          end
        end
      end

      def export_file_name(type)
        if @config.slug == ''
          "#{type}.csv"
        else
          "#{@config.slug}-data-dictionary-#{@standard_version}-#{type}.csv"
        end
      end

      def generic_folder_path(file, type)
        file.gsub(/#{type}\//, '').split('/')[0..-2].join('/')
      end

      def extract_domain_name(file)
        file.gsub(/domains\//, '').split('/').last.to_s.gsub(/.json/, '')
      end
    end
  end
end
