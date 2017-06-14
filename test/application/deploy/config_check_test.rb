# frozen_string_literal: true

require "test_helpers/sandbox"
require "test_helpers/capture"

module ApplicationTests
  module DeployTests
    # Tests to assure loading from `.spout.yml` configuration file.
    class ConfigCheckTest < SandboxTest
      include TestHelpers::Capture

      def setup
        build_app
        basic_info
        app_file ".spout.yml", <<-YML
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

      def test_deploy_command_without_options
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch ["deploy"] }
        end
        assert_match "  `.spout.yml` Check:", output
      end

      def test_config_fail_does_not_proceed_to_following_step
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch ["deploy"] }
        end
        refute_match "user_authorization_check", output
      end

      def test_deploy_without_webserver
        app_file ".spout.yml", <<-YML
---
slug: myrepo
        YML
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch ["deploy"] }
        end
        assert_match "Please specify a webserver in your `.spout.yml` file", output
      end

      def test_deploy_with_ambiguous_webserver_name
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch %w(deploy l) }
        end
        assert_match "2 webservers match 'l'.", output
        assert_match "Did you mean one of the following?", output
        assert_match "local, live", output
      end

      def test_deploy_with_nonexistant_webserver_name
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch %w(deploy noserver) }
        end
        assert_match "0 webservers match 'noserver'.", output
        assert_match "The following webservers exist in your `.spout.yml` file:", output
        assert_match "local, live, production, test, staging, emptyurl, invalidurl", output
      end

      def test_deploy_with_webserver_without_url
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch %w(deploy empty) }
        end
        assert_match "Invalid URL format for emptyurl webserver:", output
        assert_match "''", output
      end

      def test_deploy_with_webserver_without_invalid_url
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch %w(deploy invalid) }
        end
        assert_match "Invalid URL format for invalidurl webserver:", output
        assert_match "'This is a sentence.'", output
      end

      def test_deploy_with_webserver_empty_dataset_slug
        app_file ".spout.yml", <<-YML
---
        YML
        output, _error = util_capture do
          Dir.chdir(app_path) { Spout.launch %w(deploy empty) }
        end
        assert_match "Please specify a dataset slug in your `.spout.yml` file", output
      end
    end
  end
end
