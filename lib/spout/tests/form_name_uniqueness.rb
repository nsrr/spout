module Spout
  module Tests
    module FormNameUniqueness
      def test_form_name_uniqueness
        files = Dir.glob("forms/**/*.json").collect{|file| file.split('/').last.downcase }
        assert_equal [], files.select{ |f| files.count(f) > 1 }.uniq
      end
    end
  end
end
