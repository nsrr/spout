require 'temp_app_loader'

module ApplicationTests
  class PngsCommandTest < SpoutAppTestCase

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_png_creation
      skip
      Dir.chdir(app_path) { Spout.launch ['pngs'] }
      assert File.directory?(File.join(app_path, 'images'))
      assert_equal "PNGS Created", "SHOW PNGS THAT ARE CREATED"
    end
  end
end
