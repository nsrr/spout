# require './table_formatting'
require 'spout/helpers/table_formatting'

class TableFormattingTest < MiniTest::Unit::TestCase
  def setup
    # @table_formatting = Spout::Helpers::TableFormatting.new
  end

  #   count:
  #        0          ->             '-'
  #       10          ->            '10'
  #     1000          ->         '1,000'
  def test_format_count_nil
    assert_equal "-", Spout::Helpers::TableFormatting::format_number(nil, :count)
  end

  def test_format_count_zero
    assert_equal "-", Spout::Helpers::TableFormatting::format_number(0, :count)
  end

  def test_format_count_ten
    assert_equal "10", Spout::Helpers::TableFormatting::format_number(10, :count)
  end

  def test_format_count_with_delimiter
    assert_equal "1,000", Spout::Helpers::TableFormatting::format_number(1000, :count)
  end

  # decimal:
  #        0          ->           '0.0'
  #       10          ->          '10.0'
  #      -50.2555     ->         '-50.3'
  #     1000          ->       '1,000.0'
  # 12412423.42252525 ->  '12,412,423.4'
  def test_format_decimal_nil
    assert_equal "-", Spout::Helpers::TableFormatting::format_number(nil, :decimal)
  end

  def test_format_decimal_nil_with_format
    assert_equal "-", Spout::Helpers::TableFormatting::format_number(nil, :decimal, "± %s")
  end

  def test_format_decimal_zero
    assert_equal "0.0", Spout::Helpers::TableFormatting::format_number(0, :decimal)
  end

  def test_format_decimal_ten
    assert_equal "10.0", Spout::Helpers::TableFormatting::format_number(10, :decimal)
  end

  def test_format_decimal_negative
    assert_equal "-50.3", Spout::Helpers::TableFormatting::format_number(-50.2555, :decimal)
  end

  def test_format_decimal_with_delimiter
    assert_equal "1,000.0", Spout::Helpers::TableFormatting::format_number(1000, :decimal)
  end

  def test_format_decimal_with_many_decimal_places
    assert_equal "12,412,423.4", Spout::Helpers::TableFormatting::format_number(12412423.42252525, :decimal)
  end

  def test_format_decimal_with_format
    assert_equal "± 40.2", Spout::Helpers::TableFormatting::format_number(40.2424, :decimal, "± %s")
  end

end
