module Spout
  module Tests
    module VariableTypeValidation
      VALID_VARIABLE_TYPES = ['identifier', 'choices', 'integer', 'numeric', 'string', 'text', 'date', 'time', 'file', 'datetime'].sort

      def assert_variable_type(item, msg = nil)
        full_message = build_message(msg, "? invalid variable type. Valid types: #{VALID_VARIABLE_TYPES.join(', ')}", item)
        assert_block(full_message) do
          VALID_VARIABLE_TYPES.include?(item)
        end
      end

      Dir.glob("variables/**/*.json").each do |file|
        define_method("test_variable_type: "+file) do
          assert_variable_type begin JSON.parse(File.read(file))["type"] rescue nil end
        end
      end

    end
  end
end
