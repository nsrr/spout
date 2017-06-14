# frozen_string_literal: true

require "test_helpers/sandbox"

module ApplicationTests
  class OptionTest < SandboxTest
    def test_valid_option
      option = Spout::Models::Option.new({ "value" => "1", "display_name" => "First Option", "description" => "First Option Description" })

      assert_equal "1", option.value
      assert_equal "First Option", option.display_name
      assert_equal "First Option Description", option.description
    end

    def test_invalid_option
      option = Spout::Models::Option.new([])

      assert_nil option.value
      assert_nil option.display_name
      assert_nil option.description

      # assert_equal 1, option.errors
      # assert_equal "Option is not correct format", option.errors.first
    end

    def test_empty_option
      option = Spout::Models::Option.new({})

      assert_nil option.value
      assert_nil option.display_name
      assert_nil option.description
    end

    def test_blank_display_name
      skip
      option = Spout::Models::Option.new({ "value" => "1", "display_name" => "", "description" => "First Option Description" })

      assert_equal "1", option.value
      assert_equal "", option.display_name
      assert_equal "First Option Description", option.description

      assert_equal 1, option.errors
      assert_equal "Option display name can't be blank", option.errors.first
    end

    def test_missing_display_name
      skip
      option = Spout::Models::Option.new({ "value" => "1", "description" => "First Option Description" })

      assert_equal "1", option.value
      assert_nil option.display_name
      assert_equal "First Option Description", option.description

      assert_equal 1, option.errors
      assert_equal "Option display name can't be blank", option.errors.first
    end

    def test_blank_value
      skip
      option = Spout::Models::Option.new({ "value" => "", "display_name" => "First Option", "description" => "First Option Description" })

      assert_equal "", option.value
      assert_equal "First Option", option.display_name
      assert_equal "First Option Description", option.description

      assert_equal 1, option.errors
      assert_equal "Option value can't be blank", option.errors.first
    end

    def test_missing_value
      skip
      option = Spout::Models::Option.new({ "display_name" => "First Option", "description" => "First Option Description" })

      assert_nil option.value
      assert_equal "First Option", option.display_name
      assert_equal "First Option Description", option.description

      assert_equal 1, option.errors
      assert_equal "Option value can't be blank", option.errors.first
    end
  end
end
