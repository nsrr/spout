require 'temp_app_loader'

module ApplicationTests
  class TestCommandTest < SpoutAppTestCase

    def setup
      build_app
      @original_stdout = $stdout
      $stdout = StringIO.new
    end

    def teardown
      $stdout = @original_stdout
      @original_stdout = nil
      teardown_app
    end

    def test_silent_tests
      skip
      assert_equal "SILENT TEST RESULT", Dir.chdir(app_path) { Spout.launch ['test'] }
    end

    def test_verbose_tests
      skip
      assert_equal "VERBOSE TEST RESULT", Dir.chdir(app_path) { Spout.launch ['test', '--verbose'] }
    end
  end
end
