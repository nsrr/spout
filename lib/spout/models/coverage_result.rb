# frozen_string_literal: true

require 'spout/tests/variable_type_validation'

module Spout
  module Models
    # Contains the coverage of a specific variable.
    class CoverageResult
      attr_accessor :error, :error_message, :file_name_test, :json_id_test,
                    :values_test, :valid_values, :csv_values,
                    :variable_type_test, :json, :domain_test

      def initialize(column, csv_values)
        load_json(column)
        load_valid_values

        @csv_values = csv_values
        @values_test = check_values
        @variable_type_test = check_variable_type
        @domain_test = check_domain_specified
      end

      def load_json(column)
        file = Dir.glob("variables/**/#{column.to_s.downcase}.json", File::FNM_CASEFOLD).first
        @file_name_test = !file.nil?
        @json = JSON.parse(File.read(file)) rescue @json = {}
        @json_id_test = (@json['id'].to_s.downcase == column)
      end

      def load_valid_values
        valid_values = []
        if @json['type'] == 'choices' || domain_name != ''
          file = Dir.glob("domains/**/#{@json['domain'].to_s.downcase}.json", File::FNM_CASEFOLD).first
          if json = JSON.parse(File.read(file)) rescue false
            valid_values = json.collect { |hash| hash['value'] }
          end
        end
        @valid_values = valid_values
      end

      def number_of_errors
        @file_name_test && @json_id_test && @values_test && @variable_type_test && @domain_test ? 0 : 1
      end

      def check_values
        @json['type'] != 'choices' || (@valid_values | @csv_values.compact).size == @valid_values.size
      end

      def check_variable_type
        Spout::Tests::VariableTypeValidation::VALID_VARIABLE_TYPES.include?(@json['type'])
      end

      def check_domain_specified
        if @json['type'] != 'choices' && domain_name == ''
          true
        else
          domain_file = Dir.glob("domains/**/#{@json['domain'].to_s.downcase}.json", File::FNM_CASEFOLD).first
          if domain_json = JSON.parse(File.read(domain_file)) rescue false
            return domain_json.is_a?(Array)
          end
          false
        end
      end

      def errored?
        error == true
      end

      def domain_name
        @json['domain'].to_s.downcase.strip
      end
    end
  end
end
