require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  class GraphsTest < SandboxTest

    include TestHelpers::Capture

    def setup
      build_app
      basic_info
    end

    def teardown
      remove_basic_info
      teardown_app
    end

    def test_graphs_command_without_visit_variable
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['graphs'] }
      end

      assert_equal "Could not find the following visit variable: visit\n", output
    end

    def test_graphs_with_visit_variable
      create_visit_variable_and_domain

      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['graphs'] }
      end

      assert File.directory?(File.join(app_path, 'graphs', '1.0.0'))
      assert_equal ["age_at_visit.json", "gender.json", "visit.json", ".progress.json", ".", ".."].sort, Dir.entries(File.join(app_path, 'graphs', '1.0.0')).sort
      assert_match /Parsing csvs\/1\.0\.0\/dataset\.csv/, output
      assert_match /of 3: age\_at\_visit/, output
      assert_match /of 3: gender/, output
      assert_match /of 3: visit/, output

      json = JSON.parse(File.read(File.join(app_path, 'graphs', '1.0.0', 'gender.json'))) rescue json = { 'charts' => {}, 'tables' => {} }
      assert_equal ["histogram", "age", "gender"], json['charts'].keys
      assert_equal ["histogram", "age", "gender"], json['tables'].keys

      remove_visit_variable_and_domain
    end

    def test_graphs_with_limited_rows
      create_visit_variable_and_domain

      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['graphs', '--rows=2'] }
      end

      assert File.directory?(File.join(app_path, 'graphs', '1.0.0'))
      assert_equal ["age_at_visit.json", "gender.json", "visit.json", ".progress.json", ".", ".."].sort, Dir.entries(File.join(app_path, 'graphs', '1.0.0')).sort
      assert_match /Parsing csvs\/1\.0\.0\/dataset\.csv/, output
      assert_match /of 3: age\_at\_visit/, output
      assert_match /of 3: gender/, output
      assert_match /of 3: visit/, output

      json = JSON.parse(File.read(File.join(app_path, 'graphs', '1.0.0', 'gender.json'))) rescue json = { 'charts' => {}, 'tables' => {} }
      assert_equal ["histogram", "age", "gender"], json['charts'].keys
      assert_equal ["histogram", "age", "gender"], json['tables'].keys
      assert_equal "2", json['tables']['histogram']['footers'].first.last['text']

      remove_visit_variable_and_domain
    end

  end
end
