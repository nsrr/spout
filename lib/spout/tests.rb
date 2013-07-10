require 'turn/autorun'
require 'test/unit'
require 'rubygems'
require 'json'

require 'spout/tests/json_validation'
require 'spout/tests/variable_type_validation'
require 'spout/tests/variable_name_uniqueness'
require 'spout/tests/domain_existence_validation'
require 'spout/tests/domain_format'
require 'spout/tests/domain_name_uniqueness'

module Spout
  module Tests
    include Spout::Tests::JsonValidation
    include Spout::Tests::VariableTypeValidation
    include Spout::Tests::VariableNameUniqueness
    include Spout::Tests::DomainExistenceValidation
    include Spout::Tests::DomainFormat
    include Spout::Tests::DomainNameUniqueness

    Turn.config.trace = 1
  end
end

require 'spout/hidden_reporter'

module Turn
  class Configuration
    def reporter
      @reporter ||= Spout::HiddenReporter.new(ENV['HIDE_PASSING_TESTS'] == 'true')
    end
  end
end
