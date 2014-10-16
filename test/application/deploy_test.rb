require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  class DeployTest < SandboxTest

    include TestHelpers::Capture

    def setup
      build_app
      basic_info
    end

    def teardown
      remove_basic_info
      teardown_app
    end

    def test_deploy_command_without_options
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['deploy'] }
      end

      assert_match "CODE GREEN INITIALIZED...", output
      assert_match "Deploying to server...", output
    end

  end
end
