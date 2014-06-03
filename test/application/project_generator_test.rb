require 'test_helpers/sandbox'

module ApplicationTests
  class ProjectGeneratorTest < SandboxTest

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
