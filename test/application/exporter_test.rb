# frozen_string_literal: true

require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  # Tests to assure that dictionary exports work.
  class ExporterTest < SandboxTest
    include TestHelpers::Capture

    def setup
      build_app
      delete_app_file('VERSION')
      basic_info
    end

    def teardown
      remove_basic_info
      teardown_app
    end

    def test_exports
      variable_csv = <<-CSV
folder,id,display_name,description,type,units,domain,labels,calculation,commonly_used,forms
"",age_at_visit,Age at Visit,Age at time of visit.,numeric,years,"",age_at_visit,"",true,""
"",gender,Gender,Gender as reported by Parent Cohort,choices,"",gdomain,gender,"",true,intake_questionnaire
      CSV
      domain_csv = <<-CSV
folder,domain_id,value,display_name,description
"",gdomain,m,Male,""
"",gdomain,f,Female,""
"",gdomain,r,Refused to Answer,""
      CSV
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['export'] }
      end
      assert File.directory?(File.join(app_path, 'dd'))
      assert_equal variable_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'variables.csv'))
      assert_equal domain_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'domains.csv'))
      assert_match 'dd/1.0.0/variables.csv', output
      assert_match 'dd/1.0.0/domains.csv', output
    end

    def test_exports_with_slug_specified
      app_file '.spout.yml', <<-YML
slug: myrepo
visit: visit
charts:
  - chart: age_at_visit
    title: Age
  - chart: gender
    title: Gender
      YML
      variable_csv = <<-CSV
folder,id,display_name,description,type,units,domain,labels,calculation,commonly_used,forms
"",age_at_visit,Age at Visit,Age at time of visit.,numeric,years,"",age_at_visit,"",true,""
"",gender,Gender,Gender as reported by Parent Cohort,choices,"",gdomain,gender,"",true,intake_questionnaire
      CSV
      domain_csv = <<-CSV
folder,domain_id,value,display_name,description
"",gdomain,m,Male,""
"",gdomain,f,Female,""
"",gdomain,r,Refused to Answer,""
      CSV
      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['export'] }
      end
      assert File.directory?(File.join(app_path, 'dd'))
      assert_equal variable_csv, File.read(
        File.join(app_path, 'dd', '1.0.0', 'myrepo-data-dictionary-1.0.0-variables.csv')
      )
      assert_equal domain_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'myrepo-data-dictionary-1.0.0-domains.csv'))
      assert_match 'dd/1.0.0/myrepo-data-dictionary-1.0.0-variables.csv', output
      assert_match 'dd/1.0.0/myrepo-data-dictionary-1.0.0-domains.csv', output
    end

    def test_export_creates_forms_csv
      form_csv = <<-CSV
folder,id,display_name,code_book
"",intake_questionnaire,Intake Questionnaire at Baseline Visit,Baseline-Visit-Intake-Questionnaire.pdf
      CSV

      output, _error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['export'] }
      end

      assert File.directory?(File.join(app_path, 'dd'))
      assert_equal form_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'forms.csv'))
      assert_match 'dd/1.0.0/forms.csv', output
    end
  end
end
