require 'test_helpers/sandbox'

module ApplicationTests
  class DictionaryTest < SandboxTest

    def setup
      build_app
      basic_info
    end

    def teardown
      remove_basic_info
      teardown_app
    end

    def test_empty_dictionary
      dictionary = Spout::Models::Dictionary.new(app_path)

      assert_equal app_path, dictionary.app_path
      assert_equal [], dictionary.variables
      assert_equal [], dictionary.domains
      assert_equal [], dictionary.forms
    end

    def test_load_variables
      dictionary = Spout::Models::Dictionary.new(app_path)
      dictionary.load_variables!

      assert_equal 2, dictionary.variables.count
    end

    def test_load_domains
      dictionary = Spout::Models::Dictionary.new(app_path)
      dictionary.load_domains!

      assert_equal 1, dictionary.domains.count
    end

    def test_load_forms
      dictionary = Spout::Models::Dictionary.new(app_path)
      dictionary.load_forms!

      assert_equal 1, dictionary.forms.count
    end

    def test_load_all
      dictionary = Spout::Models::Dictionary.new(app_path)
      dictionary.load_all!

      assert_equal 2, dictionary.variables.count
      assert_equal 1, dictionary.domains.count
      assert_equal 1, dictionary.forms.count
    end

  end
end
