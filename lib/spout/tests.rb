# frozen_string_literal: true

require "rubygems"
require "json"

require "minitest/autorun"
require "minitest/reporters"
require "colorize"

module Minitest
  module Reporters
    class SpoutReporter < BaseReporter
      include RelativePosition

      def start
        super
        print "Loaded Suite test".colorize(:white)
        puts
        puts
        puts "Started"
        puts
      end

      def report
        super
        puts format("Finished in %.5f seconds.", total_time)
        puts
        print format("%d tests", count).colorize(:white)
        print format(", %d assertions, ", assertions)
        color = failures.zero? && errors.zero? ? :green : :red
        print format("%d failures, %d errors, ", failures, errors).colorize(color)
        print format("%d skips", skips).colorize(:yellow)
        puts
        puts
      end

      def record(test)
        super
        if !test.skipped? && test.failure
          print "    "
          print_colored_status(test)
          print "    #{test.name}"
          puts
          print "             "
          print test.failure.to_s.gsub("\n", "\n             ")
          puts
          puts
        end
      end

      protected

      def print_colored_status(test)
        color = if test.passed?
                  :green
                elsif test.skipped?
                  :yellow
                else
                  :red
                end
        print pad_mark(result(test).to_s.upcase).colorize(color)
      end

      def before_suite(suite)
        puts suite
      end

      def after_suite(suite)
        puts
      end
    end
  end
end

Minitest::Reporters.use! Minitest::Reporters::SpoutReporter.new

require "spout/tests/json_validation"
require "spout/tests/domain_existence_validation"
require "spout/tests/domain_format"
require "spout/tests/domain_name_format"
require "spout/tests/domain_name_uniqueness"
require "spout/tests/domain_specified"
require "spout/tests/form_existence_validation"
require "spout/tests/form_name_format"
require "spout/tests/form_name_match"
require "spout/tests/form_name_uniqueness"
require "spout/tests/variable_display_name_length"
require "spout/tests/variable_name_format"
require "spout/tests/variable_name_match"
require "spout/tests/variable_name_uniqueness"
require "spout/tests/variable_type_validation"

require "spout/helpers/iterators"

module Spout
  module Tests
    include Spout::Tests::JsonValidation
    include Spout::Tests::DomainExistenceValidation
    include Spout::Tests::DomainFormat
    include Spout::Tests::DomainNameFormat
    include Spout::Tests::DomainNameUniqueness
    include Spout::Tests::DomainSpecified
    include Spout::Tests::FormExistenceValidation
    include Spout::Tests::FormNameFormat
    include Spout::Tests::FormNameMatch
    include Spout::Tests::FormNameUniqueness
    include Spout::Tests::VariableDisplayNameLength
    include Spout::Tests::VariableNameFormat
    include Spout::Tests::VariableNameMatch
    include Spout::Tests::VariableNameUniqueness
    include Spout::Tests::VariableTypeValidation
  end
end

# Initialize the String class `@disable_colorization` instance variable
String.disable_colorization = false
