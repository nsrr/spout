# frozen_string_literal: true

require 'test_helpers/sandbox'

module ApplicationTests
  # Tests to assure forms are formatted correctly.
  class FormTest < SandboxTest
    def setup
      build_app
      basic_info
    end

    def teardown
      remove_basic_info
      teardown_app
    end

    def test_valid_form
      form = Spout::Models::Form.new(File.join(app_path, 'forms', 'intake_questionnaire.json'), app_path)
      assert_equal 0, form.errors.size
      assert_equal 'intake_questionnaire',                    form.id
      assert_equal 'Intake Questionnaire at Baseline Visit',  form.display_name
      assert_equal 'Baseline-Visit-Intake-Questionnaire.pdf', form.code_book
    end

    def test_blank_hash
      app_file 'forms/empty.json', <<-JSON
        {
        }
      JSON
      form = Spout::Models::Form.new(File.join(app_path, 'forms', 'empty.json'), app_path)
      assert_equal 1, form.errors.size
      assert_equal "'id': nil does not match filename \"empty\"", form.errors.first
      delete_app_file 'forms/empty.json'
    end

    def test_not_a_hash
      app_file 'forms/array.json', <<-JSON
        []
      JSON
      form = Spout::Models::Form.new(File.join(app_path, 'forms', 'array.json'), app_path)
      assert_equal 'array', form.id
      assert_equal 1, form.errors.size
      assert_match(/Form must be a valid hash in the following format:/, form.errors.first)
      delete_app_file 'forms/array.json'
    end

    def test_filename_should_match_id
      app_file 'forms/mismatch-id.json', <<-JSON
        {
          "id": "id-mismatch",
          "display_name": "The Great Mismatch",
          "code_book": "How to Mismatch Things.pdf"
        }
      JSON
      form = Spout::Models::Form.new(File.join(app_path, 'forms', 'mismatch-id.json'), app_path)
      assert_equal 1, form.errors.size
      assert_equal "'id': \"id-mismatch\" does not match filename \"mismatch-id\"", form.errors.first
      delete_app_file 'forms/mismatch-id.json'
    end
  end
end
