require 'turn/autorun'
require 'test/unit'
require 'rubygems'
require 'json'

require 'spout/tests/domain_existence_validation'
require 'spout/tests/json_validation'
require 'spout/tests/variable_type_validation'

module Spout
  module Tests
    include Spout::Tests::JsonValidation
    include Spout::Tests::VariableTypeValidation
    include Spout::Tests::DomainExistenceValidation

    Turn.config.trace = 1
  end
end
