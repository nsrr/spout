module Spout
  module Tests
    module JsonValidation

      Dir.glob("variables/**/*.json").each do |file|
        define_method("test_json: "+file) do
          assert_equal true, (!!JSON.parse(File.read(file)) rescue false)
        end
      end

      Dir.glob("domains/**/*.json").each do |file|
        define_method("test_json: "+file) do
          assert_equal true, (!!JSON.parse(File.read(file)) rescue false)
        end
      end

    end
  end
end
