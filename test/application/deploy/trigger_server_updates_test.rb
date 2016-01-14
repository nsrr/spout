require 'colorize'

require 'test_helpers/sandbox'
require 'test_helpers/capture'
require 'test_helpers/nsrr'

module ApplicationTests
  module DeployTests
    class TriggerServerUpdatesTest < SandboxTest
      include TestHelpers::Capture
      include TestHelpers::Nsrr

      def setup
        build_app
        basic_info
        app_file '.spout.yml', <<-YML
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
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=1-abcd', '--skip-checks', '--skip-tests', '--skip-coverage', '--skip-variables'] }
          end
          assert_match 'Launch Server Scripts: DONE', output.uncolorize
        end
      end

      def test_trigger_update_failure
        skip
        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=3-ijkl', '--skip-checks', '--skip-tests', '--skip-coverage', '--skip-variables'] }
          end
          assert_match 'Launch Server Scripts: FAIL', output.uncolorize
        end
      end
    end
  end
end
