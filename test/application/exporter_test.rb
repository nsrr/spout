require 'temp_app_loader'

module ApplicationTests
  class ExporterTest < SpoutAppTestCase

    def setup
      build_app
      app_file 'variables/age_at_visit.json', <<-JSON
      {
        "id": "age_at_visit",
        "display_name": "Age at Visit",
        "description": "Age at time of visit.",
        "type": "numeric",
        "units": "years",
        "labels": [
          "age_at_visit"
        ],
        "commonly_used": true
      }
      JSON
      app_file 'variables/gender.json', <<-JSON
        {
          "id": "gender",
          "display_name": "Gender",
          "description": "Gender as reported by Parent Cohort",
          "type": "choices",
          "domain": "gender12",
          "labels": [
            "gender"
          ],
          "commonly_used": true
        }
      JSON
      app_file 'domains/gender12.json', <<-JSON
        [
          {
            "value": "1",
            "display_name": "Male",
            "description": ""
          },
          {
            "value": "2",
            "display_name": "Female",
            "description": ""
          }
        ]
      JSON
    end

    def teardown
      teardown_app
    end

    def test_exports
      variable_csv = <<-CSV
folder,id,display_name,description,type,units,domain,labels,calculation
"",age_at_visit,Age at Visit,Age at time of visit.,numeric,years,"",age_at_visit,""
"",gender,Gender,Gender as reported by Parent Cohort,choices,"",gender12,gender,""
      CSV

      domain_csv = <<-CSV
folder,domain_id,value,display_name,description
"",gender12,1,Male,""
"",gender12,2,Female,""
      CSV

      Dir.chdir(app_path) { Spout.launch ['export'] }
      assert File.directory?(File.join(app_path, 'dd'))
      assert_equal variable_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'variables.csv'))
      assert_equal domain_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'domains.csv'))
    end
  end
end
