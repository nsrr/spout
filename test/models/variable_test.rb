require 'test_helpers/sandbox'

module ApplicationTests
  class VariableTest < SandboxTest

    def setup
      build_app
      basic_info
    end

    def teardown
      remove_basic_info
      teardown_app
    end

    def test_valid_choices_variable
      variable = Spout::Models::Variable.new(File.join(app_path, 'variables', 'gender.json'), app_path)

      assert_equal 0, variable.errors.size
      assert_equal "gender",      variable.id
      assert_equal "Gender",      variable.display_name
      assert_equal "Gender as reported by Parent Cohort", variable.description
      assert_equal "choices",     variable.type
      assert_equal "gdomain",     variable.domain_name
      assert_equal [ "gender" ],  variable.labels
      assert_equal true,          variable.commonly_used
    end

    def test_valid_numeric_variable
      variable = Spout::Models::Variable.new(File.join(app_path, 'variables', 'age_at_visit.json'), app_path)

      assert_equal 0, variable.errors.size
      assert_equal "age_at_visit",      variable.id
      assert_equal "Age at Visit",      variable.display_name
      assert_equal "Age at time of visit.", variable.description
      assert_equal "numeric",           variable.type
      assert_equal "years",             variable.units
      assert_equal nil,                 variable.domain_name
      assert_equal [ "age_at_visit" ],  variable.labels
      assert_equal true,                variable.commonly_used
    end

    def test_missing_domain_for_choices_variable
      skip
      app_file 'variables/nodomain.json', <<-JSON
        {
          "id": "nodomain",
          "display_name": "No Domain",
          "type": "choices"
        }
      JSON

      variable = Spout::Models::Variable.new(File.join(app_path, 'variables', 'nodomain.json'), app_path)

      assert_equal 1, variable.errors.size
      assert_equal "No domain specified for variable of type choices", variable.errors.first
      delete_app_file 'variables/nodomain.json'
    end

    def test_filename_should_match_id
      app_file 'variables/mismatch-id.json', <<-JSON
        {
          "id": "id-mismatch",
          "display_name": "The Great Mismatch",
          "type": "numeric"
        }
      JSON
      variable = Spout::Models::Variable.new(File.join(app_path, 'variables', 'mismatch-id.json'), app_path)

      assert_equal 1, variable.errors.size
      assert_equal "'id': \"id-mismatch\" does not match filename \"mismatch-id\"", variable.errors.first

      delete_app_file 'variables/mismatch-id.json'
    end

    def test_not_a_hash
      app_file 'variables/array.json', <<-JSON
        []
      JSON
      variable = Spout::Models::Variable.new(File.join(app_path, 'variables', 'array.json'), app_path)

      assert_equal 'array', variable.id
      assert_equal 1, variable.errors.size
      assert_match /Variable must be a valid hash in the following format:/, variable.errors.first

      delete_app_file 'variables/array.json'
    end

  end
end
