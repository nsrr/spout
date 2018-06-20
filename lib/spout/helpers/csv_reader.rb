# frozen_string_literal: true

require "csv"

module Spout
  module Helpers
    # Reads CSVs and handles conversion of characters into UTF-8 format.
    class CSVReader
      def self.read_csv(csv_file)
        File.open(csv_file, "r:iso-8859-1:utf-8") do |file|
          csv = CSV.new(file, headers: true, header_converters: ->(h) { h.to_s.downcase })
          while line = csv.shift # rubocop:disable Lint/AssignmentInCondition
            yield line.to_hash
          end
        end
      end
    end
  end
end
