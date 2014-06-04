require 'json'

require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  class ImporterTest < SandboxTest

    include TestHelpers::Capture

    def setup
      build_app
      app_file 'variables-import.csv', <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,gender,Gender,Gender Description,choices,gdomain,,,gender
      CSV
      app_file 'domains-import.csv', <<-CSV
folder,domain_id,display_name,description,value
,gdomain,Male,,m
,gdomain,Female,,f
      CSV
    end

    def teardown
      teardown_app
    end

    def test_import_with_missing_csv
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['import'] }
      end

      assert_match /Usage: spout import CSVFILE/, output
      assert_match /The CSVFILE must be the location of a valid CSV file\./, output
    end

    def test_variable_imports
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['import', 'variables-import.csv'] }
      end

      variable_json = <<-JSON
{
  "id": "gender",
  "display_name": "Gender",
  "description": "Gender Description",
  "type": "choices",
  "domain": "gdomain",
  "labels": [
    "gender"
  ]
}
      JSON

      assert_equal 1, Dir.glob(File.join(app_path, 'variables', '**', '*.json')).count
      assert_match /create(.*)variables\/Demographics\/gender\.json/, output
      assert_equal variable_json, File.read(File.join(app_path, 'variables', 'Demographics', 'gender.json'))
    end

    def test_domain_imports
      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['import', 'domains-import.csv', '--domains'] }
      end

      domain_json = <<-JSON
[
  {
    "value": "m",
    "display_name": "Male",
    "description": ""
  },
  {
    "value": "f",
    "display_name": "Female",
    "description": ""
  }
]
      JSON

      assert_equal 1, Dir.glob(File.join(app_path, 'domains', '**', '*.json')).count
      assert_match /create(.*)domains\/gdomain\.json/, output
      assert_equal domain_json, File.read(File.join(app_path, 'domains', 'gdomain.json'))
    end
  end
end
