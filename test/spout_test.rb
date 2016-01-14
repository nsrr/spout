require 'test_helper'

# Basic spout tests
class SpoutTest < Minitest::Test
  def test_spout_application
    assert_kind_of Module, Spout
  end

  def test_spout_version
    assert_kind_of String, Spout::VERSION::STRING
  end
end
