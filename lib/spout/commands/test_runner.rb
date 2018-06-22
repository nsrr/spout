# frozen_string_literal: true

module Spout
  module Commands
    # Runs spout tests.
    class TestRunner
      class << self
        def run
          new.run
        end
      end

      def run
        $LOAD_PATH.unshift File.join(Dir.pwd, "test")
        Dir.glob(test_files, File::FNM_CASEFOLD).each do |test_file|
          require test_file
        end
      end

      def test_files
        File.join(Dir.pwd, "test", "*_test.rb")
      end
    end
  end
end
