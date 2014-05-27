require 'spout/models/subject'


module Spout
  module Helpers
    class SubjectLoader
      attr_accessor :subjects
      attr_reader :all_methods

      def initialize(variable_files, valid_ids, standard_version, number_of_rows, visit)
        @subjects = []
        @variable_files = variable_files
        @valid_ids = valid_ids
        @standard_version = standard_version
        @number_of_rows = number_of_rows
        @visit = visit
        @all_methods = {}
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
            puts "Line: #{count}" if (count % 1000 == 0)
            @subjects << Spout::Models::Subject.create do |t|
              t._visit = row[@visit]

              row.each do |key,value|
                unless t.respond_to?(key)
                  t.class.send(:define_method, "#{key}") { instance_variable_get("@#{key}") }
                  t.class.send(:define_method, "#{key}=") { |value| instance_variable_set("@#{key}", value) }
                  all_methods[key] ||= []
                  all_methods[key] << csv_file
                end

                unless value == nil
                  t.send("#{key}=", value)
                end
              end
            end
            # puts "Memory Used: " + (`ps -o rss -p #{$$}`.strip.split.last.to_i / 1024).to_s + " MB" if count % 1000 == 0
            # break if count >= 1000
            break if @number_of_rows != nil and count >= @number_of_rows
          end
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
    end
  end
end
