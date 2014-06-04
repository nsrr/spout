require 'csv'
require 'json'

require 'spout/models/subject'

module Spout
  module Helpers
    class SubjectLoader
      attr_accessor :subjects
      attr_reader :all_methods, :all_domains

      def initialize(variable_files, valid_ids, standard_version, number_of_rows, visit)
        @subjects = []
        @variable_files = variable_files
        @valid_ids = valid_ids
        @standard_version = standard_version
        @number_of_rows = number_of_rows
        @visit = visit
        @all_methods = {}
        @all_domains = []
      end

      def load_subjects_from_csvs!
        load_subjects_from_csvs_part_one!
        load_subjects_from_csvs_part_two!
      end

      def load_subjects_from_csvs_part_one!
        @subjects = []

        csv_files = Dir.glob("csvs/#{@standard_version}/*.csv")
        csv_files.each_with_index do |csv_file, index|
          count = 0
          puts "Parsing: #{csv_file}"
          CSV.parse( File.open(csv_file, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true, header_converters: lambda { |h| h.to_s.downcase } ) do |line|
            row = line.to_hash
            count += 1
            print '.' if (count % 10 == 0)
            @subjects << Spout::Models::Subject.create do |t|
              t._visit = row[@visit]

              row.each do |key,value|
                method = key.to_s.downcase

                unless t.respond_to?(method)
                  t.class.send(:define_method, "#{method}") { instance_variable_get("@#{method}") }
                  t.class.send(:define_method, "#{method}=") { |value| instance_variable_set("@#{method}", value) }
                end

                @all_methods[method] ||= []
                @all_methods[method] = @all_methods[method] | [csv_file]

                unless value == nil
                  t.send("#{method}=", value)
                end
              end
            end
            # puts "Memory Used: " + (`ps -o rss -p #{$$}`.strip.split.last.to_i / 1024).to_s + " MB" if count % 1000 == 0
            break if @number_of_rows != nil and count >= @number_of_rows
          end
          puts "\n\n"
        end
      end

      def load_subjects_from_csvs_part_two!
        @variable_files.each do |variable_file|
          json = JSON.parse(File.read(variable_file)) rescue json = nil
          next unless json
          next unless @valid_ids.include?(json["id"].to_s.downcase) or @valid_ids.size == 0
          next unless ["numeric", "integer"].include?(json["type"])
          method  = json['id'].to_s.downcase
          next unless Spout::Models::Subject.method_defined?(method)

          @subjects.each{ |s| s.send(method) != nil ? s.send("#{method}=", s.send("#{method}").to_f) : nil }
        end
        @subjects
      end

      def load_variable_domains!
        @variable_files.each do |variable_file|
          json = JSON.parse(File.read(variable_file)) rescue json = nil
          next unless json
          next unless ["choices"].include?(json["type"])
          domain = json['domain'].to_s.downcase
          @all_domains << domain
        end
        @all_domains = @all_domains.compact.uniq.sort
      end
    end
  end
end
