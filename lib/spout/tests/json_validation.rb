module Spout
  module Tests
    module JsonValidation

      def assert_valid_json(item, msg = nil)
        result = begin
          !!JSON.parse(File.read(item))
        rescue JSON::ParserError => e
          error = e
          false
        end
        full_message = build_message(msg, "?", error)
        assert_block(full_message) do
          result
        end
      end

      Dir.glob("variables/**/*.json").each do |file|
        define_method("test_json: "+file) do
          assert_valid_json file
        end
      end

      Dir.glob("domains/**/*.json").each do |file|
        define_method("test_json: "+file) do
          assert_valid_json file
        end
      end

      Dir.glob("forms/**/*.json").each do |file|
        define_method("test_json: "+file) do
          assert_valid_json file
        end
      end

    end
  end
end
