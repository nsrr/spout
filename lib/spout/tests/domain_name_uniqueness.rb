module Spout
  module Tests
    module DomainNameUniqueness
      def test_domain_name_uniqueness
        files = Dir.glob("domains/**/*.json").collect{|file| file.split('/').last.downcase }
        assert_equal [], files.select{ |f| files.count(f) > 1 }.uniq
      end
    end
  end
end
