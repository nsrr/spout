require 'turn/autorun'
require 'test/unit'
require 'rubygems'
require 'json'

require 'spout/tests/domain_existence_validation'
require 'spout/tests/json_validation'
require 'spout/tests/variable_type_validation'
require 'spout/tests/domain_format'

module Spout
  module Tests
    include Spout::Tests::JsonValidation
    include Spout::Tests::VariableTypeValidation
    include Spout::Tests::DomainExistenceValidation
    include Spout::Tests::DomainFormat

    Turn.config.trace = 1
  end
end

require 'spout/hidden_reporter'

module Turn
  class Configuration
    def reporter
      @reporter ||= Spout::HiddenReporter.new(ENV['VERBOSE_TESTS'] == 'true')
    end
  end
end
