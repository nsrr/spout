module Spout
  module Tests
    module DomainExistenceValidation

      def assert_domain_existence(item, msg = nil)
        domain_names = Dir.glob("domains/**/*.json").collect{|file| file.split('/').last.to_s.downcase.split('.json').first}

        result = begin
          domain_name = JSON.parse(File.read(item))["domain"]
          domain_names.include?(domain_name)
        rescue JSON::ParserError
          domain_name = ''
          false
        end

        full_message = build_message(msg, "The domain #{domain_name} referenced by ? does not exist.", item)
        assert_block(full_message) do
          result
        end
      end

      Dir.glob("variables/**/*.json").each do |file|
        if (not [nil, ''].include?(JSON.parse(File.read(file))["domain"]) rescue false)
          define_method("test_domain_exists: "+file) do
            assert_domain_existence file
          end
        end
      end

    end
  end
end
