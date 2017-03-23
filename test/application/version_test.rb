# frozen_string_literal: true

require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  # Tests to assure version is printed.
  class VersionTest < SandboxTest
    include TestHelpers::Capture

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_version
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['version'] }
      end
      assert_equal "Spout #{Spout::VERSION::STRING}\n", output
    end
  end
end
