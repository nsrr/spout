# frozen_string_literal: true

require "json"
require "fileutils"
require "colorize"

require "spout/helpers/csv_reader"

module Spout
  module Commands
    class Importer
      def initialize(argv)
        use_domains = !argv.delete("--domains").nil?
        use_forms = !argv.delete("--forms").nil?
        @preserve_case = !argv.delete("--preserve-case").nil?
        @csv_file = argv[1].to_s
        unless File.exist?(@csv_file)
          puts csv_usage
          return self
        end
        if use_domains
          import_domains
        elsif use_forms
          import_forms
        else
          import_variables
        end
      end

      def csv_usage
        usage = <<-EOT

Usage: spout import CSVFILE

The CSVFILE must be the location of a valid CSV file.

EOT
        usage
      end

      def import_variables
        Spout::Helpers::CSVReader.read_csv(@csv_file) do |row|
          if not row.keys.include?("id")
            puts "\nMissing column header `".colorize( :red ) + "id".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
            exit(1)
          end
          next if row["id"] == ""
          folder = File.join("variables", row.delete("folder").to_s)
          FileUtils.mkpath folder
          hash = {}
          id = row.delete("id").to_s.downcase
          hash["id"] = id
          hash["display_name"] = tenderize(row.delete("display_name").to_s)
          hash["description"] = row.delete("description").to_s
          hash["type"] = row.delete("type")
          domain = row.delete("domain").to_s.downcase
          hash["domain"] = domain if domain != ""
          units = row.delete("units").to_s
          hash["units"] = units if units != ""
          calculation = row.delete("calculation").to_s
          hash["calculation"] = calculation if calculation != ""
          labels = row.delete("labels").to_s.split(";")
          hash["labels"] = labels unless labels.empty?
          hash["commonly_used"] = true if row.delete("commonly_used").to_s.casecmp("true").zero?
          forms = row.delete("forms").to_s.split(";")
          hash["forms"] = forms unless forms.empty?
          hash["other"] = row unless row.empty?

          file_name = File.join(folder, "#{id}.json")
          File.open(file_name, "w") do |file|
            file.write(JSON.pretty_generate(hash) + "\n")
          end
          puts "      create".colorize( :green ) + "  #{file_name}"
        end
      end

      def import_domains
        domains = {}

        Spout::Helpers::CSVReader.read_csv(@csv_file) do |row|
          if not row.keys.include?("domain_id")
            puts "\nMissing column header `".colorize( :red ) + "domain_id".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
            exit(1)
          end
          if not row.keys.include?("value")
            puts "\nMissing column header `".colorize( :red ) + "value".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
            exit(1)
          end
          if not row.keys.include?("display_name")
            puts "\nMissing column header `".colorize( :red ) + "display_name".colorize( :light_cyan ) + "` in data dictionary.".colorize( :red ) + additional_csv_info
            exit(1)
          end

          next if row["domain_id"].to_s == "" or row["value"].to_s == "" or row["display_name"].to_s == ""
          folder = File.join("domains", row["folder"].to_s).gsub(/[^a-zA-Z0-9_\/\.-]/, "_")
          domain_name = row["domain_id"].to_s.gsub(/[^a-zA-Z0-9_\/\.-]/, "_").downcase
          domains[domain_name] ||= {}
          domains[domain_name]["folder"] = folder
          domains[domain_name]["options"] ||= []

          hash = {}
          hash["value"] = row.delete("value").to_s
          hash["display_name"] = tenderize(row.delete("display_name").to_s)
          hash["description"] = row.delete("description").to_s
          hash["missing"] = true if hash["value"].match(/^[\.-]/)

          domains[domain_name]["options"] << hash
        end

        domains.each do |domain_name, domain_hash|
          folder = domain_hash["folder"]
          FileUtils.mkpath folder

          file_name = File.join(folder, "#{domain_name}.json")

          File.open(file_name, "w") do |file|
            file.write(JSON.pretty_generate(domain_hash["options"]) + "\n")
          end
          puts "      create".colorize( :green ) + "  #{file_name}"
        end
      end

      def import_forms
        Spout::Helpers::CSVReader.read_csv(@csv_file) do |row|
          unless row.keys.include?("id")
            puts "\nMissing column header `".colorize(:red) +
                 "id".colorize(:light_cyan) +
                 "` in data dictionary.".colorize(:red) +
                 additional_csv_info
            exit(1)
          end
          unless row.keys.include?("display_name")
            puts "\nMissing column header `".colorize(:red) +
                 "display_name".colorize(:light_cyan) +
                 "` in data dictionary.".colorize(:red) +
                 additional_csv_info
            exit(1)
          end
          next if row["id"] == ""
          folder = File.join("forms", row.delete("folder").to_s)
          FileUtils.mkpath folder
          hash = {}
          id = row.delete("id").to_s.downcase
          hash["id"] = id
          hash["display_name"] = tenderize(row.delete("display_name").to_s)
          hash["code_book"] = row.delete("code_book").to_s
          hash["other"] = row unless row.empty?
          file_name = File.join(folder, "#{id}.json")
          File.open(file_name, "w") do |file|
            file.write(JSON.pretty_generate(hash) + "\n")
          end
          puts "      create".colorize(:green) + "  #{file_name}"
        end
      end

      # Converts ALL-CAPS display names to title case
      # Ex: BODY MASS INDEX changes to Body Mass Index
      # Ex: Patient ID stays the same as Patient ID
      def tenderize(text)
        return text if @preserve_case
        if /[a-z]/ =~ text
          text
        else
          text.downcase.gsub(/\b\w/) { $&.upcase }
        end
      end

      private

      def additional_csv_info
        "\n\nFor additional information on specifying CSV column headers before import see:\n\n    " +
          "https://github.com/sleepepi/spout#generate-a-new-repository-from-an-existing-csv-file".colorize(:light_cyan) + "\n\n"
      end
    end
  end
end
