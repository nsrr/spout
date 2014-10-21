require 'colorize'

require 'test_helpers/sandbox'
require 'test_helpers/capture'
require 'test_helpers/nsrr'

module ApplicationTests
  module DeployTests
    class VersionCheckTest < SandboxTest

      include TestHelpers::Capture
      include TestHelpers::Nsrr

      def setup
        build_app
        basic_info
        app_file '.spout.yml', <<-YML
---
webservers:
  - name: local
    url: http://localhost
  - name: live
    url: https://live.sleepdata.org
  - name: production
    url: https://production.sleepdata.org
  - name: test
    url: http://test.sleepdata.org
  - name: staging
    url: http://staging.sleepdata.org
  - name: emptyurl
  - name: invalidurl
    url: This is a sentence.
slug: myrepo
        YML
      end

      def teardown
        remove_basic_info
        teardown_app
      end

      def test_changelog_version_matches
        app_file 'CHANGELOG.md', <<-YML
## 1.0.0
- My first entry
        YML

        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=1-abcd', '--no-graphs', '--no-images', '--no-server-updates'] }
          end
          assert_match "CHANGELOG.md: PASS ## 1.0.0", output.uncolorize
        end
      end

      def test_changelog_version_does_not_match
        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=1-abcd', '--no-graphs', '--no-images', '--no-server-updates'] }
          end
          assert_match "Expected: ## 1.0.0", output.uncolorize
          assert_match "Actual: ", output.uncolorize
        end
      end

      def test_git_tag_matches
        app_file 'CHANGELOG.md', <<-YML
## 1.0.0
- My first entry
        YML

        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) do
              `git init`
              `git add .`
              `git commit -m "Initial commit"`
              `git tag -a "v1.0.0" -m "v1.0.0"`
              Spout.launch ['deploy', 't', '--token=1-abcd', '--no-graphs', '--no-images', '--no-server-updates']
            end
          end
          assert_match "CHANGELOG.md: PASS ## 1.0.0", output.uncolorize
        end
      end

      def test_git_tag_does_not_match
        app_file 'CHANGELOG.md', <<-YML
## 1.0.0
- My first entry
        YML

        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) do
              `git init`
              `git add .`
              `git commit -m "Initial commit"`
              Spout.launch ['deploy', 't', '--token=1-abcd', '--no-graphs', '--no-images', '--no-server-updates']
            end
          end
          assert_match "Version specified in `VERSION` file 'v1.0.0' does not match git tag on HEAD commit ''", output.uncolorize
        end
      end

      def test_git_uncommitted_changes
        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) do
              `git init`
              Spout.launch ['deploy', 't', '--token=1-abcd', '--no-graphs', '--no-images', '--no-server-updates']
            end
          end
          assert_match "Git Status Check: FAIL", output.uncolorize
          assert_match "working directory contains uncomitted changes", output.uncolorize
        end
      end

    end
  end
end
