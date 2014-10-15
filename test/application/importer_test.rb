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

    def test_import_converts_ids_to_lowercase
      app_file 'variables-import-uppercase-ids.csv', <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,BMI,Body Mass Index,Body Mass Index Description,numeric,,,,bmi
Measurements,RdI3P,Respiratory Index,RDI Description,numeric,,,,ahi
      CSV

      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['import', 'variables-import-uppercase-ids.csv'] }
      end

      bmi_json = JSON.parse(File.read(File.join(app_path, 'variables', 'Demographics', 'bmi.json')))
      assert_equal 'bmi', bmi_json['id']

      rdi3p_json = JSON.parse(File.read(File.join(app_path, 'variables', 'Measurements', 'rdi3p.json')))
      assert_equal 'rdi3p', rdi3p_json['id']
    end

    def test_import_converts_domain_ids_to_lowercase
      app_file 'variables-import-uppercase-domains-ids.csv', <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,gender,Gender,Gender Description,choices,GDomain,,,gender
      CSV

      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['import', 'variables-import-uppercase-domains-ids.csv'] }
      end

      gender_json = JSON.parse(File.read(File.join(app_path, 'variables', 'Demographics', 'gender.json')))
      assert_equal 'gdomain', gender_json['domain']
    end

    def test_import_removes_all_caps_from_display_names
      app_file 'variables-import-all-caps-display-names.csv', <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,BMI,BODY MASS INDEX,Body Mass Index Description,numeric,,,,bmi
Measurements,RdI3P,Respiratory index for PT,RDI Description,numeric,,,,ahi
      CSV

      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['import', 'variables-import-all-caps-display-names.csv'] }
      end

      bmi_json = JSON.parse(File.read(File.join(app_path, 'variables', 'Demographics', 'bmi.json')))
      assert_equal 'Body Mass Index', bmi_json['display_name']

      rdi3p_json = JSON.parse(File.read(File.join(app_path, 'variables', 'Measurements', 'rdi3p.json')))
      assert_equal 'Respiratory index for PT', rdi3p_json['display_name']
    end

  end
end
