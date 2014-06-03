require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  class TestCommandTest < SandboxTest

    include TestHelpers::Capture

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_silent_tests
      skip
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['test'] }
      end
      assert_match /Loaded Suite test\n\n/, output
      assert_match /DictionaryTest/, output
      refute_match /PASS (.*?) test_domain_name_uniqueness/, output
      refute_match /PASS (.*?) test_variable_name_uniqueness/, output
      assert_match /2 tests, 2 passed, 0 failures, 0 errors, 0 skips, 2 assertions/, output
    end

    def test_verbose_tests
      skip
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['test', '--verbose'] }
      end

      assert_match /Loaded Suite test\n\n/, output
      assert_match /DictionaryTest/, output
      assert_match /PASS (.*?) test_domain_name_uniqueness/, output
      assert_match /PASS (.*?) test_variable_name_uniqueness/, output
      assert_match /2 tests, 2 passed, 0 failures, 0 errors, 0 skips, 2 assertions/, output
    end
  end
end
