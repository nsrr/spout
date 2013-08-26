require 'spout/tests/json_helper'

module Spout
  module Tests
    module DomainSpecified

      def assert_domain_specified(domain_name, msg = nil)
        full_message = build_message(msg, "Variables of type choices need to specify a domain.")
        assert_block(full_message) do
          domain_name != nil
        end
      end

      Dir.glob("variables/**/*.json").each do |file|
        if json_value(file, :type) == "choices"
          define_method("test_domain_specified:"+file) do
            assert_domain_present json_value(file, :domain)
          end
        end
      end

    end
  end
end
