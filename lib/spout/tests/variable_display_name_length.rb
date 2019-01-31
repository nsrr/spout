# frozen_string_literal: true

module Spout
  module Tests
    module VariableDisplayNameLength
      Dir.glob("variables/**/*.json").each do |file|
        define_method("test_variable_display_name_length: "+file) do
          assert_operator 255, :>=, (begin JSON.parse(File.read(file, encoding: "utf-8"))["display_name"].size rescue 0 end)
        end
      end
    end
  end
end
