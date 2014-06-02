require 'temp_app_loader'

module ApplicationTests
  class OutliersTest < SpoutAppTestCase

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_outliers
      skip
      # TODO Test missing outliers
      Dir.chdir(app_path) { Spout.launch ['outliers'] }
      assert_equal "Outliers", [1,2,3,4]
    end
  end
end
