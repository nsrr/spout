require 'simplecov'
# require 'test/unit'
# require 'turn/autorun'

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require File.expand_path('../../lib/spout', __FILE__)
