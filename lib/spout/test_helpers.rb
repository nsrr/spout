require 'turn/autorun'
require 'test/unit'
require 'rubygems'
require 'json'

module Spout
  module TestHelpers

    VALID_VARIABLE_TYPES = ['identifier', 'choices', 'integer', 'numeric']

    class TestCase < Test::Unit::TestCase
      Dir.glob("domains/**/*.json").each do |file|
        define_method("test_json: "+file) do
          assert_equal true, (!!JSON.parse(File.read(file)) rescue false)
        end
      end

      Dir.glob("variables/**/*.json").each do |file|

        define_method("test_json: "+file) do
          assert_equal true, (!!JSON.parse(File.read(file)) rescue false)
        end

        define_method("test_variable_type: "+file) do
          assert_equal true, (::VALID_VARIABLE_TYPES.include?(JSON.parse(File.read(file))["type"]) rescue false)
        end

        if (not [nil, ''].include?(JSON.parse(File.read(file))["domain"]) rescue false)
          define_method("test_domain_exists: "+file) do
            assert_equal true, (File.exists?(File.join("domains", JSON.parse(File.read(file))["domain"]+".json")) rescue false)
          end
        end

      end
    end

  end
end
