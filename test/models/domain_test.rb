# frozen_string_literal: true

require "test_helpers/sandbox"

module ApplicationTests
  # Tests to assure domains are formatted correctly.
  class DomainTest < SandboxTest
    def setup
      build_app
      basic_info
    end

    def teardown
      remove_basic_info
      teardown_app
    end

    def test_valid_domain
      domain = Spout::Models::Domain.new(File.join(app_path, "domains", "gdomain.json"), app_path)

      assert_equal "gdomain", domain.id
      assert_equal 3, domain.options.size

      assert_equal "m", domain.options[0].value
      assert_equal "Male", domain.options[0].display_name
      assert_equal "", domain.options[0].description
      refute_equal true, domain.options[0].missing

      assert_equal "f", domain.options[1].value
      assert_equal "Female", domain.options[1].display_name
      assert_equal "", domain.options[1].description
      refute_equal true, domain.options[1].missing

      assert_equal "r", domain.options[2].value
      assert_equal "Refused to Answer", domain.options[2].display_name
      assert_equal "", domain.options[2].description
      assert_equal true, domain.options[2].missing
    end

    def test_non_existent_file
      domain = Spout::Models::Domain.new(File.join(app_path, "domains", "does_not_exist.json"), app_path)
      assert_equal "does_not_exist", domain.id
      assert_equal [], domain.options
      assert_equal 1, domain.errors.count
      assert_equal "No corresponding does_not_exist.json file found.", domain.errors.first
    end

    def test_for_parsing_error_trailing_comma
      app_file "domains/trailing-comma.json", <<-JSON
        [
          {
            "value": "m",
            "display_name": "Male",
            "description": ""
          },
        ]
      JSON

      domain = Spout::Models::Domain.new(File.join(app_path, "domains", "trailing-comma.json"), app_path)
      assert_equal [], domain.options
      assert_equal 1, domain.errors.count
      assert_equal "trailing-comma", domain.id
      assert_match(/Parsing error found in trailing-comma\.json: /, domain.errors.first)

      delete_app_file "domains/trailing-comma.json"
    end

    def test_not_an_array
      app_file "domains/hash.json", <<-JSON
        {}
      JSON

      domain = Spout::Models::Domain.new(File.join(app_path, "domains", "hash.json"), app_path)

      assert_equal "hash", domain.id
      assert_equal 1, domain.errors.size
      assert_match(/Domain must be a valid array in the following format:/, domain.errors.first)

      delete_app_file "domains/hash.json"
    end
  end
end
