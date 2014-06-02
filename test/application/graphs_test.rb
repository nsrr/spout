require 'temp_app_loader'

module ApplicationTests
  class GraphsTest < SpoutAppTestCase

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_graphs_command
      skip
      Dir.chdir(app_path) { Spout.launch ['graphs'] }
      assert_equal "Graphs Created", "Five Graphs Created in JSON Format"
    end
  end
end
