# frozen_string_literal: true

module Spout
  module Tests
    module FormExistenceValidation

      def assert_form_existence(item)
        form_names = Dir.glob("forms/**/*.json").collect{|file| file.split('/').last.to_s.downcase.split('.json').first}

        result = begin
          (form_names | JSON.parse(File.read(item))["forms"]).size == form_names.size
        rescue JSON::ParserError
          false
        end

        message = "One or more forms referenced by #{item} does not exist."

        assert result, message
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
