# frozen_string_literal: true

require "test_helpers/sandbox"
require "test_helpers/capture"
require "test_helpers/nsrr"

module ApplicationTests
  module DeployTests
    # Tests to assure that server scripts are launched.
    class TriggerServerUpdatesTest < SandboxTest
      include TestHelpers::Capture
      include TestHelpers::Nsrr

      def setup
        build_app
        basic_info
        app_file ".spout.yml", <<-YML
---
webservers:
  - name: test
    url: http://test.sleepdata.org
slug: myrepo
        YML
      end

      def teardown
        remove_basic_info
        teardown_app
      end

      def test_editor_approved_access
        skip
        Artifice.activate_with(app) do
          output, _error = util_capture do
            Dir.chdir(app_path) do
              Spout.launch %w(deploy t --token=1-abcd --skip-checks --skip-tests --skip-coverage --skip-variables)
            end
          end
          assert_match "Launch Server Scripts: DONE", output.colorless
        end
      end

      def test_trigger_update_failure
        skip
        Artifice.activate_with(app) do
          output, _error = util_capture do
            Dir.chdir(app_path) do
              Spout.launch %w(deploy t --token=3-ijkl --skip-checks --skip-tests --skip-coverage --skip-variables)
            end
          end
          assert_match "Launch Server Scripts: FAIL", output.colorless
        end
      end
    end
  end
end
