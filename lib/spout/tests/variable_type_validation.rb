# frozen_string_literal: true

module Spout
  module Tests
    module VariableTypeValidation
      VALID_VARIABLE_TYPES = ['identifier', 'choices', 'integer', 'numeric', 'string', 'text', 'date', 'time', 'file', 'datetime'].sort

      def assert_variable_type(item)
        message = "#{item} invalid variable type. Valid types: #{VALID_VARIABLE_TYPES.join(', ')}"
        assert VALID_VARIABLE_TYPES.include?(item), message
      end

      Dir.glob("variables/**/*.json").each do |file|
        define_method("test_variable_type: "+file) do
          assert_variable_type begin JSON.parse(File.read(file))["type"] rescue nil end
        end
      end

    end
  end
end
