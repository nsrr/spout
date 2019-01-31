# frozen_string_literal: true

module Spout
  module Tests
    # If a variable references a domain, then the domain should exist and be
    # defined.
    module DomainExistenceValidation
      def assert_domain_existence(item)
        domain_names = Dir.glob("domains/**/*.json").collect do |file|
          file.split("/").last.to_s.downcase.split(".json").first
        end
        result = begin
          domain_name = JSON.parse(File.read(item, encoding: "utf-8"))["domain"]
          domain_names.include?(domain_name)
        rescue JSON::ParserError
          domain_name = ""
          false
        end
        message = "The domain #{domain_name} referenced by #{item} does not exist."
        assert result, message
      end

      Dir.glob("variables/**/*.json").each do |file|
        if (not [nil, ""].include?(JSON.parse(File.read(file, encoding: "utf-8"))["domain"]) rescue false)
          define_method("test_domain_exists: #{file}") do
            assert_domain_existence file
          end
        end
      end
    end
  end
end
