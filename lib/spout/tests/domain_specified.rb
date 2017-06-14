# frozen_string_literal: true

require "spout/tests/json_helper"

module Spout
  module Tests
    module DomainSpecified
      Dir.glob("variables/**/*.json").each do |file|
        if json_value(file, :type) == "choices"
          define_method("test_domain_specified:"+file) do
            domain_name = json_value(file, :domain)
            assert domain_name != nil, "Variables of type choices need to specify a domain."
          end
        end
      end
    end
  end
end
