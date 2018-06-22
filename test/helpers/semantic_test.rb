# frozen_string_literal: true

require "test_helper"
require "spout/helpers/semantic"

module HelperTests
  class SemanticTest < Minitest::Test
    def test_no_match
      @semantic = Spout::Helpers::Semantic.new("0.1.0", ["0.2.0", "0.3.0", "0.4.0", "0.4.0.rc"].shuffle)
      assert_equal "0.1.0", @semantic.version
      assert_equal "0", @semantic.major
      assert_equal "1", @semantic.minor
      assert_equal "0", @semantic.tiny
      assert_nil @semantic.build
      assert_equal [], @semantic.valid_versions.collect(&:string)
      assert_equal "0.1.0", @semantic.selected_folder
    end

    def test_exact_match
      @semantic = Spout::Helpers::Semantic.new("0.2.0", ["0.2.0", "0.3.0", "0.4.0", "0.4.0.rc"].shuffle)
      assert_equal "0.2.0", @semantic.version
      assert_equal "0", @semantic.major
      assert_equal "2", @semantic.minor
      assert_equal "0", @semantic.tiny
      assert_nil @semantic.build
      assert_equal ["0.2.0"], @semantic.valid_versions.collect(&:string)
      assert_equal "0.2.0", @semantic.selected_folder
    end

    def test_higher_minor_version
      @semantic = Spout::Helpers::Semantic.new("0.4.1.beta1", ["0.2.0", "0.3.0", "0.4.0", "0.4.1", "0.4.0.rc", "0.4.1.pre"].shuffle)
      assert_equal "0.4.1.beta1", @semantic.version
      assert_equal "0", @semantic.major
      assert_equal "4", @semantic.minor
      assert_equal "1", @semantic.tiny
      assert_equal "beta1", @semantic.build
      assert_equal ["0.4.0.rc", "0.4.0", "0.4.1.pre", "0.4.1"], @semantic.valid_versions.collect(&:string)
      assert_equal "0.4.1", @semantic.selected_folder
    end

    def test_exact_match_with_higher_minor_version
      @semantic = Spout::Helpers::Semantic.new("0.4.1.pre", ["0.2.0", "0.3.0", "0.4.0", "0.4.1", "0.4.0.rc", "0.4.1.pre"].shuffle)
      assert_equal "0.4.1.pre", @semantic.version
      assert_equal "0", @semantic.major
      assert_equal "4", @semantic.minor
      assert_equal "1", @semantic.tiny
      assert_equal "pre", @semantic.build
      assert_equal ["0.4.0.rc", "0.4.0", "0.4.1.pre", "0.4.1"], @semantic.valid_versions.collect(&:string)
      assert_equal "0.4.1.pre", @semantic.selected_folder
    end

    def test_nil_version
      @semantic = Spout::Helpers::Semantic.new(nil, [])
      assert_equal "", @semantic.version
      assert_nil @semantic.major
      assert_nil @semantic.minor
      assert_nil @semantic.tiny
      assert_nil @semantic.build
      assert_equal [], @semantic.valid_versions.collect(&:string)
      assert_equal "", @semantic.selected_folder
    end

    def test_blank_version
      @semantic = Spout::Helpers::Semantic.new("", [])
      assert_equal "", @semantic.version
      assert_nil @semantic.major
      assert_nil @semantic.minor
      assert_nil @semantic.tiny
      assert_nil @semantic.build
      assert_equal [], @semantic.valid_versions.collect(&:string)
      assert_equal "", @semantic.selected_folder
    end
  end
end
