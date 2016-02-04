# frozen_string_literal: true

module Spout
  module Tests
    module FormNameMatch
      Dir.glob("forms/**/*.json").each do |file|
        define_method("test_form_name_match: "+file) do
          assert_equal file.gsub(/^.*\//, '').gsub('.json', '').downcase, (begin JSON.parse(File.read(file))["id"] rescue nil end)
        end
      end
    end
  end
end
