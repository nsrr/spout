# frozen_string_literal: true

require "test_helpers/sandbox"

module ApplicationTests
  # Tests to assure spout project directory structure is generated.
  class ProjectGeneratorTest < SandboxTest
    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_file_structure
      assert_equal(
        [
          "domains", "forms", "test", "variables", ".gitignore",
          ".ruby-version", ".spout.yml", ".travis.yml", "gems.rb", "Rakefile",
          "CHANGELOG.md", "README.md", "VERSION", ".", ".."
        ].sort,
        Dir.entries(app_path).sort
      )
    end
  end
end
