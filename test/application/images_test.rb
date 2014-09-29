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

      assert_match /phantomjs (.*?)\/age\_at\_visit\.png/, output
      assert_match /phantomjs (.*?)\/gender\.png/, output
      assert_match /phantomjs (.*?)\/visit\.png/, output

      assert_match /phantomjs (.*?)\/age\_at\_visit-lg\.png/, output
      assert_match /phantomjs (.*?)\/gender-lg\.png/, output
      assert_match /phantomjs (.*?)\/visit-lg\.png/, output
    end

    def test_png_creation_for_single_variable
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['pngs', '--pretend', 'visit'] }
      end

      assert File.directory?(File.join(app_path, 'images', '1.0.0'))

      refute_match /phantomjs (.*?)\/age\_at\_visit\.png/, output
      refute_match /phantomjs (.*?)\/gender\.png/, output
      assert_match /phantomjs (.*?)\/visit\.png/, output
    end

    def test_png_creation_for_choices_variable_type
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['pngs', '--pretend', '--type-choices'] }
      end

      assert File.directory?(File.join(app_path, 'images', '1.0.0'))

      refute_match /phantomjs (.*?)\/age\_at\_visit\.png/, output
      assert_match /phantomjs (.*?)\/gender\.png/, output
      assert_match /phantomjs (.*?)\/visit\.png/, output
    end

    def test_png_creation_for_numeric_variable_type
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['pngs', '--pretend', '--type-numeric'] }
      end

      assert File.directory?(File.join(app_path, 'images', '1.0.0'))

      assert_match /phantomjs (.*?)\/age\_at\_visit\.png/, output
      refute_match /phantomjs (.*?)\/gender\.png/, output
      refute_match /phantomjs (.*?)\/visit\.png/, output
    end

    def test_png_creation_for_large_images
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['pngs', '--pretend', '--size-lg'] }
      end

      assert File.directory?(File.join(app_path, 'images', '1.0.0'))

      assert_match /phantomjs (.*?)\/age\_at\_visit-lg\.png/, output
      assert_match /phantomjs (.*?)\/gender-lg\.png/, output
      assert_match /phantomjs (.*?)\/visit-lg\.png/, output

      refute_match /phantomjs (.*?)\/age\_at\_visit\.png/, output
      refute_match /phantomjs (.*?)\/gender\.png/, output
      refute_match /phantomjs (.*?)\/visit\.png/, output
    end

    def test_png_creation_for_small_images
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['pngs', '--pretend', '--size-sm'] }
      end

      assert File.directory?(File.join(app_path, 'images', '1.0.0'))

      refute_match /phantomjs (.*?)\/age\_at\_visit-lg\.png/, output
      refute_match /phantomjs (.*?)\/gender-lg\.png/, output
      refute_match /phantomjs (.*?)\/visit-lg\.png/, output

      assert_match /phantomjs (.*?)\/age\_at\_visit\.png/, output
      assert_match /phantomjs (.*?)\/gender\.png/, output
      assert_match /phantomjs (.*?)\/visit\.png/, output
    end

  end
end
