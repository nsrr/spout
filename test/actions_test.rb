require 'test_helper'

class ActionsTest < Test::Unit::TestCase

  def test_version_command
    assert_nil Spout::Actions.new.interpret(['v'])
  end

  def test_help_command
    assert_nil Spout::Actions.new.interpret(['h'])
  end

end
