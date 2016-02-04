# frozen_string_literal: true

module Spout
  module Tests
    module DomainFormat

      def assert_domain_format(item)
        result = begin
          json = JSON.parse(File.read(item))
          if json.is_a?(Array)
            json.empty? or json.select{|o| not o.is_a?(Hash)}.size == 0
          else
            false
          end
        rescue JSON::ParserError
          false
        end

        message = "Must be an array of choice hashes. Ex:\n[\n  {\n    \"value\":        \"1\",\n    \"display_name\": \"Option 1\",\n    \"description\":  \"...\"\n  },\n  { ... },\n  ...\n]"

        assert result, message
      end

      Dir.glob("domains/**/*.json").each do |file|
        define_method("test_domain_format: "+file) do
          assert_domain_format file
        end
      end

    end
  end
end
