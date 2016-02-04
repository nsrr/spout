# frozen_string_literal: true

module Spout
  module Tests
    module VariableNameUniqueness
      def test_variable_name_uniqueness
        files = Dir.glob("variables/**/*.json").collect{|file| file.split('/').last.downcase }
        assert_equal [], files.select{ |f| files.count(f) > 1 }.uniq
      end
    end
  end
end
