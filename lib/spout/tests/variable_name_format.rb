# frozen_string_literal: true

module Spout
  module Tests
    # Tests to assure that the variable name starts with a lowercase letter
    # followed by lowercase letters, numbers, or underscores
    module VariableNameFormat
      Dir.glob('variables/**/*.json').each do |file|
        define_method("test_variable_name_format: #{file}") do
          message = 'Variable name format error. Name must start with a lowercase letter and be followed by lowercase letters, numbers, or underscores'
          assert_match(/^[a-z]\w*$/, (begin JSON.parse(File.read(file))['id'] rescue nil end), message)
        end
      end
    end
  end
end
