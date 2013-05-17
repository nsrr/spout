module Spout
  module Tests
    module DomainFormat

      def assert_domain_format(item, msg = nil)
        result = begin
          json = JSON.parse(File.read(item))
          if json.kind_of?(Array)
            json.empty? or json.select{|o| not o.kind_of?(Hash)}.size == 0
          else
            false
          end
        rescue JSON::ParserError
          false
        end

        full_message = build_message(msg, "Must be an array of choice hashes. Ex:\n[\n  {\n    \"value\":        \"1\",\n    \"display_name\": \"Option 1\",\n    \"description\":  \"...\"\n  },\n  { ... },\n  ...\n]")
        assert_block(full_message) do
          result
        end
      end

      Dir.glob("domains/**/*.json").each do |file|
        define_method("test_json: "+file) do
          assert_domain_format file
        end
      end

    end
  end
end
