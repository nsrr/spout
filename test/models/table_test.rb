require 'test_helpers/sandbox'
require 'test_helpers/capture'

require 'spout/models/table'
require 'spout/helpers/config_reader'
require 'spout/helpers/subject_loader'

module ApplicationTests
  class TableTest < SandboxTest

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
          visit = Spout::Models::Variable.find_by_id 'visit'
          table = Spout::Models::Table.new('gender', @subject_loader.subjects, variable, "All Visits")

          assert_equal 'Age at Visit by Gender', table.title
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
          @variable_files = Dir.glob('variables/**/*.json')
          @config = Spout::Helpers::ConfigReader.new
          @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], '1.0.0', nil, @config.visit)
          @subject_loader.load_subjects_from_csvs!

          variable = Spout::Models::Variable.find_by_id 'gender'
          visit = Spout::Models::Variable.find_by_id 'visit'
          table = Spout::Models::Table.new('race', @subject_loader.subjects, variable, nil)

          assert_equal 'Gender by Race', table.title
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

  end
end
