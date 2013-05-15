module Spout
  module Tests
    module DomainExistenceValidation

      Dir.glob("variables/**/*.json").each do |file|
        if (not [nil, ''].include?(JSON.parse(File.read(file))["domain"]) rescue false)
          define_method("test_domain_exists: "+file) do
            assert_equal true, (File.exists?(File.join("domains", JSON.parse(File.read(file))["domain"]+".json")) rescue false)
          end
        end
      end

    end
  end
end
