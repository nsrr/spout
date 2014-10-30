require 'test_helpers/sandbox'
require 'test_helpers/capture'

require 'spout/models/tables'
require 'spout/helpers/config_reader'
require 'spout/helpers/subject_loader'

module ApplicationTests
  class TablesTest < SandboxTest

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

    def test_numeric_vs_choices_table
      Dir.chdir(app_path) do
        output, error = util_capture do
          @variable_files = Dir.glob('variables/**/*.json')
          @config = Spout::Helpers::ConfigReader.new
          @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], '1.0.0', nil, @config.visit)
          @subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          chart_variable = Spout::Models::Variable.find_by_id 'gender'
          visit = Spout::Models::Variable.find_by_id 'visit'
          table = Spout::Models::Tables.for(variable, chart_variable, @subject_loader.subjects, "All Visits")

          assert_equal 'Gender vs Age at Visit', table.title
          assert_equal 'All Visits', table.subtitle
          assert_equal [["", "N", "Mean", "StdDev", "Median", "Min", "Max", "Unknown", "Total"]], table.headers
          assert_equal [[{ text: "Total", style: "font-weight:bold" },
                         { text: "18",    style: "font-weight:bold" },
                         { text: "38.8",  style: "font-weight:bold" },
                         { text: "± 9.4", style: "font-weight:bold" },
                         { text: "39.5",  style: "font-weight:bold" },
                         { text: "22.0",  style: "font-weight:bold" },
                         { text: "53.0",  style: "font-weight:bold" },
                         { text: "-",     style: "font-weight:bold" },
                         { text: "18",    style: "font-weight:bold" }]], table.footers
          assert_equal [["Male",   "9", "40.7",  "± 8.7", "42.0", "28.0", "53.0", "-", { text: "9", style: "font-weight:bold" }],
                        ["Female", "9", "37.0", "± 10.2", "35.0", "22.0", "53.0", "-", { text: "9", style: "font-weight:bold" }]], table.rows
          assert_equal Hash, table.to_hash.class
        end
      end
    end

    def test_choices_vs_choices_table
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
          @variable_files = Dir.glob('variables/**/*.json')
          @config = Spout::Helpers::ConfigReader.new
          @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], '1.0.0', nil, @config.visit)
          @subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'gender'
          chart_variable = Spout::Models::Variable.find_by_id 'race'
          table = Spout::Models::Tables.for(variable, chart_variable, @subject_loader.subjects, nil)

          assert_equal 'Gender vs Race', table.title
          assert_equal nil, table.subtitle
          assert_equal [["", "White", "Black", "Total"]], table.headers
          assert_equal [[{ text: "Total", style: "font-weight:bold" },
                         { text: "10",    style: "font-weight:bold" },
                         { text: "8",     style: "font-weight:bold" },
                         { text: "18",    style: "font-weight:bold" }]], table.footers
          assert_equal [["Male",   "3", "6", { text: "9", style: "font-weight:bold" }],
                        ["Female", "7", "2", { text: "9", style: "font-weight:bold" }]], table.rows
          assert_equal Hash, table.to_hash.class
        end
      end
    end

    def test_numeric_vs_numeric_table
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
          @variable_files = Dir.glob('variables/**/*.json')
          @config = Spout::Helpers::ConfigReader.new
          @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], '1.0.0', nil, @config.visit)
          @subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'bmi'
          chart_variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          table = Spout::Models::Tables.for(variable, chart_variable, @subject_loader.subjects, nil)

          assert_equal 'Age at Visit vs Body Mass Index', table.title
          assert_equal nil, table.subtitle
          assert_equal [["", "N", "Mean", "StdDev", "Median", "Min", "Max", "Unknown", "Total"]], table.headers
          assert_equal [[{ text: "Total", style: "font-weight:bold" },
                         { text: "18",    style: "font-weight:bold" },
                         { text: "20.4",  style: "font-weight:bold" },
                         { text: "± 4.2", style: "font-weight:bold" },
                         { text: "20.0",  style: "font-weight:bold" },
                         { text: "15.0",  style: "font-weight:bold" },
                         { text: "30.0",  style: "font-weight:bold" },
                         { text: "-",     style: "font-weight:bold" },
                         { text: "18",    style: "font-weight:bold" }]], table.footers
          assert_equal [["22.0 to 30.0 years", "5", "18.8", "± 4.5", "17.0", "15.0", "25.0", "-", { text: "5", style: "font-weight:bold" }],
                        ["33.0 to 40.0 years", "5", "21.2", "± 3.7", "20.0", "17.0", "27.0", "-", { text: "5", style: "font-weight:bold" }],
                        ["42.0 to 47.0 years", "4", "20.3", "± 4.3", "20.5", "15.0", "25.0", "-", { text: "4", style: "font-weight:bold" }],
                        ["48.0 to 53.0 years", "4", "21.8", "± 5.6", "19.5", "18.0", "30.0", "-", { text: "4", style: "font-weight:bold" }]], table.rows
          assert_equal Hash, table.to_hash.class
        end
      end
    end

    def test_choices_vs_numeric_table
      Dir.chdir(app_path) do
        output, error = util_capture do
          @variable_files = Dir.glob('variables/**/*.json')
          @config = Spout::Helpers::ConfigReader.new
          @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], '1.0.0', nil, @config.visit)
          @subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'gender'
          chart_variable = Spout::Models::Variable.find_by_id 'age_at_visit'
          table = Spout::Models::Tables.for(variable, chart_variable, @subject_loader.subjects, nil)

          assert_equal 'Gender vs Age at Visit', table.title
          assert_equal nil, table.subtitle
          assert_equal [["", "22.0 to 30.0 years", "33.0 to 40.0 years", "42.0 to 47.0 years", "48.0 to 53.0 years", "Total"]], table.headers
          assert_equal [[{ text: "Total", style: "font-weight:bold" },
                         { text: "5",     style: "font-weight:bold" },
                         { text: "5",     style: "font-weight:bold" },
                         { text: "4",     style: "font-weight:bold" },
                         { text: "4",     style: "font-weight:bold" },
                         { text: "18",    style: "font-weight:bold" }]], table.footers
          assert_equal [["Male", "2", "2", "3", "2", { text: "9",  style: "font-weight:bold" }],
                        ["Female", "3", "3", "1", "2", { text: "9", style: "font-weight:bold"}]], table.rows
          assert_equal Hash, table.to_hash.class
        end
      end
    end

  end
end
