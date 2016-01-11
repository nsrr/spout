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
        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=1-abcd', '--no-checks', '--no-graphs', '--no-images'] }
          end

          assert_match 'Launch Server Scripts: DONE', output.uncolorize
        end
      end

      def test_trigger_update_failure
        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=3-ijkl', '--no-checks', '--no-graphs', '--no-images'] }
          end

          assert_match 'Launch Server Scripts: FAIL', output.uncolorize
        end
      end

      def test_server_message_tag_checkout_error
        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=4-mnop', '--no-checks', '--no-graphs', '--no-images'] }
          end

          assert_match 'Launch Server Scripts: FAIL', output.uncolorize
          assert_match 'Tag not found in repository, resolve using: git push --tags', output.uncolorize
        end
      end

      def test_server_message_data_dictionary_git_repo_does_not_exist
        Artifice.activate_with(app) do
          output, error = util_capture do
            Dir.chdir(app_path) { Spout.launch ['deploy', 't', '--token=5-qrst', '--no-checks', '--no-graphs', '--no-images'] }
          end

          assert_match 'Launch Server Scripts: FAIL', output.uncolorize
          assert_match 'Dataset data dictionary git repository has not been cloned on the server. Contact server admin.', output.uncolorize
        end
      end
    end
  end
end
