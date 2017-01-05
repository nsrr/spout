require 'test_helpers/sandbox'
require 'test_helpers/capture'

require 'spout/models/graphables'
require 'spout/helpers/config_reader'
require 'spout/helpers/subject_loader'

module ApplicationTests
  class GraphablesTest < SandboxTest
    include TestHelpers::Capture

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
      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          chart_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, nil, subject_loader.subjects)

          assert_equal 'Age at Visit', graph.title
          assert_equal 'By Visit', graph.subtitle
          assert_equal ["22 to 25", "25 to 27", "27 to 30", "30 to 32", "32 to 35", "35 to 38", "38 to 40", "40 to 43", "43 to 45", "45 to 48", "48 to 50", "50 to 53"], graph.categories
          assert_equal 'Subjects', graph.units
          assert_equal [{ name: "Visit One", data: [1, nil, 3, nil, 1, nil, 1, 1, 1, 1, nil, 1] }, { name: "Visit Two", data: [nil, 1, nil, nil, 2, nil, 1, nil, 1, 1, 1, 1] }], graph.series
          assert_nil graph.stacking
          assert_equal 'years', graph.x_axis_title
          assert_equal Hash, graph.to_hash.class
        end
      end
    end

    def test_histogram_choices_graph
      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'gender'
          chart_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, nil, subject_loader.subjects)

          assert_equal 'Gender', graph.title
          assert_equal 'By Visit', graph.subtitle
          assert_equal ['Male', 'Female'], graph.categories
          assert_equal 'Subjects', graph.units
          assert_equal [{ name: "Visit One", data: [5, 5] }, { name: "Visit Two", data: [4, 4] }], graph.series
          assert_nil graph.stacking
          assert_nil graph.x_axis_title
          assert_equal Hash, graph.to_hash.class
        end
      end
    end

    def test_histogram_choices_without_domain_graph
      app_file 'variables/nodomain.json', <<-JSON
        {
          "id": "nodomain",
          "display_name": "No Domain For Variable",
          "type": "choices"
        }
      JSON

app_file 'csvs/1.0.0/dataset.csv', <<-CSV
visit,age_at_visit,gender,nodomain
1,30,m,10
1,40,m,21
1,42,m,43
1,28,m,21
1,48,m,10
1,22,f,21
1,53,f,10
1,30,f,21
1,44,f,10
1,34,f,21
2,45,m,43
2,47,m,21
2,33,m,10
2,53,m,21
2,27,f,10
2,35,f,21
2,49,f,10
2,39,f,21
      CSV

      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'nodomain'
          chart_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, nil, subject_loader.subjects)

          assert_nil graph.to_hash
        end
      end
    end

    def test_histogram_for_variable_not_in_dataset_graph
      app_file 'variables/notindataset.json', <<-JSON
        {
          "id": "notindataset",
          "display_name": "No Column in Dataset For Variable",
          "type": "numeric"
        }
      JSON

      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'notindataset'
          chart_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, nil, subject_loader.subjects)

          assert_nil graph.to_hash
        end
      end
    end

    # def test_histogram_integer_graph
    #   graph = Spout::Models::Graph.new()

    #   assert_equal true, false
    # end

    # def test_histogram_text_graph
    #   graph = Spout::Models::Graph.new()

    #   assert_nil graph
    # end

    def test_numeric_vs_choices_graph
      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          chart_variable = Spout::Models::Variable.find_by_id 'gender'
          stratification_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, stratification_variable, subject_loader.subjects)

          assert_equal 'Age at Visit by Gender', graph.title
          assert_equal 'By Visit', graph.subtitle
          assert_equal ['Visit One', 'Visit Two'], graph.categories
          assert_equal 'years', graph.units
          assert_equal [{ name: "Male", data: [37.6, 44.5] }, { name: "Female", data: [36.6, 37.5] }], graph.series
          assert_nil graph.stacking
          assert_nil graph.x_axis_title
          assert_equal Hash, graph.to_hash.class
        end
      end
    end

    def test_choices_vs_choices_graph
      app_file 'csvs/1.0.0/dataset.csv', <<-CSV
visit,age_at_visit,gender,race
1,30,m,b
1,40,m,b
1,42,m,w
1,28,m,b
1,48,m,w
1,22,f,w
1,53,f,b
1,30,f,w
1,44,f,w
1,34,f,w
2,45,m,b
2,47,m,b
2,33,m,w
2,53,m,b
2,27,f,w
2,35,f,w
2,49,f,b
2,39,f,w
      CSV

      app_file 'variables/race.json', <<-JSON
        {
          "id": "race",
          "display_name": "Race",
          "type": "choices",
          "domain": "race"
        }
      JSON
      app_file 'domains/race.json', <<-JSON
        [
          {
            "value": "w",
            "display_name": "White"
          },
          {
            "value": "b",
            "display_name": "Black"
          }
        ]
      JSON

      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'gender'
          chart_variable = Spout::Models::Variable.find_by_id 'race'
          stratification_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, stratification_variable, subject_loader.subjects)

          assert_equal 'Gender by Race', graph.title
          assert_equal 'By Visit', graph.subtitle
          assert_equal ['White', 'Black'], graph.categories
          assert_equal 'percent', graph.units
          assert_equal [{ name: "Male", data: [3, 6] }, { name: "Female", data: [7, 2] }], graph.series
          assert_equal 'percent', graph.stacking
          assert_nil graph.x_axis_title
          assert_equal Hash, graph.to_hash.class
        end
      end
    end

    def test_choices_vs_numeric_graph
      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'gender'
          chart_variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          stratification_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, stratification_variable, subject_loader.subjects)

          assert_equal 'Gender by Age at Visit', graph.title
          assert_equal 'By Visit', graph.subtitle
          assert_equal ["22.0 to 30.0", "33.0 to 40.0", "42.0 to 47.0", "48.0 to 53.0"], graph.categories
          assert_equal 'percent', graph.units
          assert_equal [{ name: "Male", data: [2, 2, 3, 2] }, { name: "Female", data: [3, 3, 1, 2] }], graph.series
          assert_equal 'percent', graph.stacking
          assert_nil graph.x_axis_title
          assert_equal Hash, graph.to_hash.class
        end
      end
    end

    def test_numeric_vs_numeric_graph
      app_file 'csvs/1.0.0/dataset.csv', <<-CSV
visit,age_at_visit,gender,bmi
1,30,m,15
1,40,m,20
1,42,m,22
1,28,m,25
1,48,m,30
1,22,f,17
1,53,f,19
1,30,f,22
1,44,f,25
1,34,f,27
2,45,m,15
2,47,m,19
2,33,m,20
2,53,m,20
2,27,f,15
2,35,f,17
2,49,f,18
2,39,f,22
      CSV

      app_file 'variables/bmi.json', <<-JSON
        {
          "id": "bmi",
          "display_name": "Body Mass Index",
          "type": "numeric",
          "units": "kilograms per square meter"
        }
      JSON

      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'bmi'
          chart_variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          stratification_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, stratification_variable, subject_loader.subjects)

          assert_equal 'Body Mass Index by Age at Visit', graph.title
          assert_equal 'By Visit', graph.subtitle
          assert_equal ['Quartile One', 'Quartile Two', 'Quartile Three', 'Quartile Four'], graph.categories
          assert_equal 'kilograms per square meter', graph.units
          assert_equal [{ name: "Visit One", data: [{ y: 19.0, stddev: '5.3', median: '17.0', min: '15.0', max: '25.0', n: 3 },
                                                    { y: 23.0, stddev: '3.6', median: '22.0', min: '20.0', max: '27.0', n: 3 },
                                                    { y: 23.5, stddev: '2.1', median: '23.5', min: '22.0', max: '25.0', n: 2 },
                                                    { y: 24.5, stddev: '7.8', median: '24.5', min: '19.0', max: '30.0', n: 2 }
                                                   ]},
                        { name: "Visit Two", data: [{ y: 17.5, stddev: '3.5', median: '17.5', min: '15.0', max: '20.0', n: 2 },
                                                    { y: 19.5, stddev: '3.5', median: '19.5', min: '17.0', max: '22.0', n: 2 },
                                                    { y: 17.0, stddev: '2.8', median: '17.0', min: '15.0', max: '19.0', n: 2 },
                                                    { y: 19.0, stddev: '1.4', median: '19.0', min: '18.0', max: '20.0', n: 2 }] }], graph.series
          assert_nil graph.stacking
          assert_nil graph.x_axis_title
          assert_equal Hash, graph.to_hash.class
        end
      end
    end

    def test_graph_creation_for_non_existent_primary_variable_do_not_exist
      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'notfound'
          chart_variable = Spout::Models::Variable.find_by_id 'gender'
          stratification_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, stratification_variable, subject_loader.subjects)

          assert_nil graph.to_hash
        end
      end
    end

    def test_graph_creation_for_non_existent_chart_variable
      Dir.chdir(app_path) do
        output, error = util_capture do
          variable_files = Dir.glob('variables/**/*.json')
          config = Spout::Helpers::ConfigReader.new
          subject_loader = Spout::Helpers::SubjectLoader.new(variable_files, [], '1.0.0', nil, config.visit)
          subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          chart_variable = Spout::Models::Variable.find_by_id 'nochart'
          stratification_variable = Spout::Models::Variable.find_by_id 'visit'
          graph = Spout::Models::Graphables.for(variable, chart_variable, stratification_variable, subject_loader.subjects)

          assert_nil graph.to_hash
        end
      end
    end
  end
end
