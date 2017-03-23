# frozen_string_literal: true

require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  # Tests to assure help command lists all commands.
  class HelpTest < SandboxTest
    include TestHelpers::Capture

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_help
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['help'] }
      end
      assert_match 'The most common spout commands are:', output
      Spout::COMMANDS.keys.each do |key|
        assert_match(/^  \[#{key}\]/, output)
      end
    end
  end
end
