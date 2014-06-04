module Spout
  module Tests
    module FormExistenceValidation

      def assert_form_existence(item, msg = nil)
        form_names = Dir.glob("forms/**/*.json").collect{|file| file.split('/').last.to_s.downcase.split('.json').first}

        result = begin
          (form_names | JSON.parse(File.read(item))["forms"]).size == form_names.size
        rescue JSON::ParserError
          false
        end

        full_message = build_message(msg, "One or more forms referenced by ? does not exist.", item)
        assert_block(full_message) do
          result
        end
      end

      Dir.glob("variables/**/*.json").each do |file|
        if (not [nil, ''].include?(JSON.parse(File.read(file))["forms"]) rescue false)
          define_method("test_form_exists: "+file) do
            assert_form_existence file
          end
        end
      end

    end
  end
end
