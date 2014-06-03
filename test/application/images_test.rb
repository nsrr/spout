require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  class ImagesTest < SandboxTest

    include TestHelpers::Capture

    def setup
      build_app
      basic_info
      create_visit_variable_and_domain
    end

    def teardown
      remove_visit_variable_and_domain
      remove_basic_info
      teardown_app
    end

    def test_png_creation
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['pngs', '--pretend'] }
      end

      assert File.directory?(File.join(app_path, 'images', '1.0.0'))

      assert_match /phantomjs (.*?)age\_at\_visit\.png/, output
      assert_match /phantomjs (.*?)gender\.png/, output
      assert_match /phantomjs (.*?)visit\.png/, output
    end
  end
end
