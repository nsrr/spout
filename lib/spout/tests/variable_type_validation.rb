module Spout
  module Tests
    module VariableTypeValidation
      VALID_VARIABLE_TYPES = ['identifier', 'choices', 'integer', 'numeric']

      Dir.glob("variables/**/*.json").each do |file|
        define_method("test_variable_type: "+file) do
          assert_equal true, (VALID_VARIABLE_TYPES.include?(JSON.parse(File.read(file))["type"]) rescue false)
        end
      end

    end
  end
end
