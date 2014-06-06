require 'rubygems'
require 'json'

require 'minitest/autorun'
require 'minitest/reporters'
require 'ansi/code'

module Minitest
  module Reporters
    class SpoutReporter < BaseReporter
      include ANSI::Code
      include RelativePosition

      def start
        super
        print(white { 'Loaded Suite test' })
        puts
        puts
        puts 'Started'
        puts
      end

      def report
        super
        puts 'Finished in %.5f seconds.' % total_time
        puts
        print(white { '%d tests' } % count)
        print(', %d assertions, ' % assertions)
        color = failures.zero? && errors.zero? ? :green : :red
        print(send(color) { '%d failures, %d errors, ' } % [failures, errors])
        print(yellow { '%d skips' } % skips)
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
          print test.failure
          puts
          puts
        end
      end

      protected

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


require 'spout/tests/json_validation'
require 'spout/tests/variable_type_validation'
require 'spout/tests/variable_name_uniqueness'
require 'spout/tests/variable_name_match'
require 'spout/tests/domain_existence_validation'
require 'spout/tests/domain_format'
require 'spout/tests/domain_name_uniqueness'
require 'spout/tests/domain_specified'
require 'spout/tests/form_existence_validation'
require 'spout/tests/form_name_uniqueness'
require 'spout/tests/form_name_match'

require 'spout/helpers/iterators'

module Spout
  module Tests
    include Spout::Tests::JsonValidation
    include Spout::Tests::VariableTypeValidation
    include Spout::Tests::VariableNameUniqueness
    include Spout::Tests::VariableNameMatch
    include Spout::Tests::DomainExistenceValidation
    include Spout::Tests::DomainFormat
    include Spout::Tests::DomainNameUniqueness
    include Spout::Tests::DomainSpecified
    include Spout::Tests::FormExistenceValidation
    include Spout::Tests::FormNameUniqueness
    include Spout::Tests::FormNameMatch
  end
end
