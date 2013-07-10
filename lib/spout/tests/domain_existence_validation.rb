module Spout
  module Tests
    module DomainExistenceValidation

      def assert_domain_existence(item, msg = nil)
        result = begin
          domain_name = JSON.parse(File.read(item))["domain"]+".json"
          Dir.glob(File.join("domains", domain_name), File::FNM_CASEFOLD).size > 0
        rescue JSON::ParserError
          false
        end
        full_message = build_message(msg, "The domain \"domains/#{domain_name}\" referenced by ? does not exist.", item)
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
