require 'temp_app_loader'

module ApplicationTests
  class HelpTest < SpoutAppTestCase

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

    def test_help
      assert_match "The most common spout commands are:", Dir.chdir(app_path) { Spout.launch ['help'] }
    end

  end
end
