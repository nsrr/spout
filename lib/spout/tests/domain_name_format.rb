module Spout
  module Tests
    # Tests to assure that the domain name starts with a lowercase letter
    # followed by lowercase letters, numbers, or underscores
    module DomainNameFormat
      Dir.glob('domains/**/*.json').each do |file|
        define_method("test_domain_name_format: #{file}") do
          message = 'Domain name format error. Name must start with a lowercase letter and be followed by lowercase letters, numbers, or underscores'
          name = File.basename(file).gsub(/\.json$/, '') rescue name = nil
          assert_match(/^[a-z]\w*$/, name, message)
        end
      end
    end
  end
end
