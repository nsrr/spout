require 'test_helpers/sandbox'

require 'spout/models/graph'
require 'spout/helpers/config_reader'
require 'spout/helpers/subject_loader'

module ApplicationTests
  class GraphTest < SandboxTest

    def setup
      build_app
      basic_info
      create_visit_variable_and_domain
    end

    def teardown
      remove_visit_variable_and_domain
      remove_basic_info
      teardown_app
    end

    # 'identifier'
    # 'choices'
    # 'integer'
    # 'numeric'
    # 'string'
    # 'text'
    # 'date'
    # 'time'
    # 'file'
    # 'datetime'

    def test_histogram_numeric_graph
      graph = Dir.chdir(app_path) do
        @variable_files = Dir.glob('variables/**/*.json')
        @config = Spout::Helpers::ConfigReader.new
        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], '1.0.0', nil, @config.visit)
        @subject_loader.load_subjects_from_csvs!

        variable = Spout::Models::Variable.find_by_id 'age_at_visit'
        Spout::Models::Graph.new('visit', @subject_loader.subjects, variable, nil)
      end

      assert_equal 'Age at Visit', graph.title
      assert_equal 'By Visit', graph.subtitle
      assert_equal ["22 to 25", "25 to 27", "27 to 30", "30 to 32", "32 to 35", "35 to 38", "38 to 40", "40 to 43", "43 to 45", "45 to 48", "48 to 50", "50 to 53"], graph.categories
      assert_equal 'Subjects', graph.units
      assert_equal [{ name: "Visit One", data: [1, nil, 3, nil, 1, nil, 1, 1, 1, 1, nil, 1] }, { name: "Visit Two", data: [nil, 1, nil, nil, 2, nil, 1, nil, 1, 1, 1, 1] }], graph.series
      assert_equal nil, graph.stacking
      assert_equal 'years', graph.x_axis_title
    end

    def test_histogram_choices_graph
      graph = Dir.chdir(app_path) do
        @variable_files = Dir.glob('variables/**/*.json')
        @config = Spout::Helpers::ConfigReader.new
        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], '1.0.0', nil, @config.visit)
        @subject_loader.load_subjects_from_csvs!

        variable = Spout::Models::Variable.find_by_id 'gender'
        Spout::Models::Graph.new('visit', @subject_loader.subjects, variable, nil)
      end

      assert_equal 'Gender', graph.title
      assert_equal 'By Visit', graph.subtitle
      assert_equal ['Male', 'Female'], graph.categories
      assert_equal 'Subjects', graph.units
      assert_equal [{ name: "Visit One", data: [5, 5, 0] }, { name: "Visit Two", data: [4, 4, 0] }], graph.series
      assert_equal nil, graph.stacking
      assert_equal nil, graph.x_axis_title
    end

    # def test_histogram_integer_graph
    #   graph = Spout::Models::Graph.new()

    #   assert_equal true, false
    # end

    # def test_histogram_text_graph
    #   graph = Spout::Models::Graph.new()

    #   assert_nil graph
    # end

  end
end
