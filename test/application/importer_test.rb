# frozen_string_literal: true

require "test_helpers/sandbox"
require "test_helpers/capture"

module ApplicationTests
  # Tests to assure that dictionary imports work.
  class ImporterTest < SandboxTest
    include TestHelpers::Capture

    def setup
      build_app
      app_file "variables-import.csv", <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels,calculation,commonly_used,forms
Demographics,gender,Gender,Gender Description,choices,gdomain,,,gender,,true,gform
      CSV
      app_file "domains-import.csv", <<-CSV
folder,domain_id,display_name,description,value
,gdomain,Male,,m
,gdomain,Female,,f
      CSV
      app_file "forms-import.csv", <<-CSV
folder,id,display_name,code_book
Demographics/Baseline,family_history,Family History,family-history.pdf
,medications,Medications,medications.pdf
      CSV
    end

    def teardown
      teardown_app
    end

    def test_import_with_missing_csv
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ["import"] }
      end

      assert_match(/Usage: spout import CSVFILE/, output)
      assert_match(/The CSVFILE must be the location of a valid CSV file\./, output)
    end

    def test_variable_imports
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "variables-import.csv"] }
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
  ],
  "commonly_used": true,
  "forms": [
    "gform"
  ]
}
      JSON

      assert_equal 1, Dir.glob(File.join(app_path, "variables", "**", "*.json")).count
      assert_match %r{create(.*)variables/Demographics/gender\.json}, output
      assert_equal variable_json, File.read(File.join(app_path, "variables", "Demographics", "gender.json"))
    end

    def test_domain_imports
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "domains-import.csv", "--domains"] }
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

      assert_equal 1, Dir.glob(File.join(app_path, "domains", "**", "*.json")).count
      assert_match %r{create(.*)domains/gdomain\.json}, output
      assert_equal domain_json, File.read(File.join(app_path, "domains", "gdomain.json"))
    end

    def test_domain_imports_with_missing_codes
      app_file "domains-import-with-missing-codes.csv", <<-CSV
folder,domain_id,display_name,description,value
,energylevel,High,,10
,energylevel,Medium,,5
,energylevel,Low,,1
,energylevel,Did Not Answer,,-1
,energylevel,Equipment Failure,,.E
      CSV

      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "domains-import-with-missing-codes.csv", "--domains"] }
      end

      domain_json = <<-JSON
[
  {
    "value": "10",
    "display_name": "High",
    "description": ""
  },
  {
    "value": "5",
    "display_name": "Medium",
    "description": ""
  },
  {
    "value": "1",
    "display_name": "Low",
    "description": ""
  },
  {
    "value": "-1",
    "display_name": "Did Not Answer",
    "description": "",
    "missing": true
  },
  {
    "value": ".E",
    "display_name": "Equipment Failure",
    "description": "",
    "missing": true
  }
]
      JSON

      assert_equal 1, Dir.glob(File.join(app_path, "domains", "**", "*.json")).count
      assert_match %r{create(.*)domains/energylevel\.json}, output
      assert_equal domain_json, File.read(File.join(app_path, "domains", "energylevel.json"))
    end

    def test_domain_remove_all_caps_from_display_names
      app_file "domains-import-with-all-caps-display-names.csv", <<-CSV
folder,domain_id,display_name,description,value
,allcaps,I AM YELLING,,1
,allcaps,No yelling please,,2
      CSV

      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "domains-import-with-all-caps-display-names.csv", "--domains"] }
      end

      domain_json = <<-JSON
[
  {
    "value": "1",
    "display_name": "I Am Yelling",
    "description": ""
  },
  {
    "value": "2",
    "display_name": "No yelling please",
    "description": ""
  }
]
      JSON

      assert_equal 1, Dir.glob(File.join(app_path, "domains", "**", "*.json")).count
      assert_match %r{create(.*)domains/allcaps\.json}, output
      assert_equal domain_json, File.read(File.join(app_path, "domains", "allcaps.json"))
    end

    def test_preserve_case
      app_file "domains-import-preserve-caps.csv", <<-CSV
folder,domain_id,display_name,description,value
,allcaps,AM/PM,,1
,allcaps,PM/AM,,2
      CSV

      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "domains-import-preserve-caps.csv", "--domains", "--preserve-case"] }
      end

      domain_json = <<-JSON
[
  {
    "value": "1",
    "display_name": "AM/PM",
    "description": ""
  },
  {
    "value": "2",
    "display_name": "PM/AM",
    "description": ""
  }
]
      JSON

      assert_equal 1, Dir.glob(File.join(app_path, "domains", "**", "*.json")).count
      assert_match %r{create(.*)domains/allcaps\.json}, output
      assert_equal domain_json, File.read(File.join(app_path, "domains", "allcaps.json"))
    end

    def test_import_converts_ids_to_lowercase
      app_file "variables-import-uppercase-ids.csv", <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,BMI,Body Mass Index,Body Mass Index Description,numeric,,,,bmi
Measurements,RdI3P,Respiratory Index,RDI Description,numeric,,,,ahi
      CSV

      util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "variables-import-uppercase-ids.csv"] }
      end

      bmi_json = JSON.parse(File.read(File.join(app_path, "variables", "Demographics", "bmi.json")))
      assert_equal "bmi", bmi_json["id"]

      rdi3p_json = JSON.parse(File.read(File.join(app_path, "variables", "Measurements", "rdi3p.json")))
      assert_equal "rdi3p", rdi3p_json["id"]
    end

    def test_import_converts_domain_ids_to_lowercase
      app_file "variables-import-uppercase-domains-ids.csv", <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,gender,Gender,Gender Description,choices,GDomain,,,gender
      CSV

      util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "variables-import-uppercase-domains-ids.csv"] }
      end

      gender_json = JSON.parse(File.read(File.join(app_path, "variables", "Demographics", "gender.json")))
      assert_equal "gdomain", gender_json["domain"]
    end

    def test_import_removes_all_caps_from_display_names
      app_file "variables-import-all-caps-display-names.csv", <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,BMI,BODY MASS INDEX,Body Mass Index Description,numeric,,,,bmi
Measurements,RdI3P,Respiratory index for PT,RDI Description,numeric,,,,ahi
      CSV
      util_capture do
        Dir.chdir(app_path) { Spout.launch ["import", "variables-import-all-caps-display-names.csv"] }
      end
      bmi_json = JSON.parse(File.read(File.join(app_path, "variables", "Demographics", "bmi.json")))
      assert_equal "Body Mass Index", bmi_json["display_name"]
      rdi3p_json = JSON.parse(File.read(File.join(app_path, "variables", "Measurements", "rdi3p.json")))
      assert_equal "Respiratory index for PT", rdi3p_json["display_name"]
    end

    def test_form_imports
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch %w(import forms-import.csv --forms) }
      end
      fx_form_json = <<-JSON
{
  "id": "family_history",
  "display_name": "Family History",
  "code_book": "family-history.pdf"
}
      JSON
      mx_form_json = <<-JSON
{
  "id": "medications",
  "display_name": "Medications",
  "code_book": "medications.pdf"
}
      JSON
      assert_equal 2, Dir.glob(File.join(app_path, "forms", "**", "*.json")).count
      assert_match %r{create(.*)forms/Demographics/Baseline/family_history\.json}, output
      assert_match %r{create(.*)forms/medications\.json}, output
      assert_equal fx_form_json, File.read(File.join(app_path, "forms", "Demographics", "Baseline", "family_history.json"))
      assert_equal mx_form_json, File.read(File.join(app_path, "forms", "medications.json"))
    end
  end
end
