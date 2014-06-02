require 'temp_app_loader'

module ApplicationTests
  class ProjectGeneratorTest < SpoutAppTestCase

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_file_structure
      assert_equal ['domains', 'test', 'variables', '.gitignore', '.ruby-version', '.spout.yml', '.travis.yml', 'Gemfile', 'Rakefile', '.', '..'].sort, Dir.entries(app_path).sort
    end
  end
end
