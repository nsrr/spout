# frozen_string_literal: true

require "test_helpers/sandbox"
require "test_helpers/capture"

module ApplicationTests
  # Tests to assure dictionary tests are run.
  class TestCommandTest < SandboxTest
    include TestHelpers::Capture

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_dictionary_tests
      skip
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ["test"] }
      end
      assert_match(/Loaded Suite test/, output)
      assert_match(/DictionaryTest/, output)
      refute_match(/PASS (.*?) test_domain_name_uniqueness/, output)
      refute_match(/PASS (.*?) test_variable_name_uniqueness/, output)
      assert_match(/2 tests, 2 passed, 0 failures, 0 errors, 0 skips, 2 assertions/, output)
    end
  end
end
