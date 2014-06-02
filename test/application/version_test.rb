require 'temp_app_loader'

module ApplicationTests
  class VersionTest < SpoutAppTestCase

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

    def test_version
      assert_equal "Spout #{Spout::VERSION::STRING}", Dir.chdir(app_path) { Spout.launch ['version'] }
    end

  end
end
