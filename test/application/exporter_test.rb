require 'csv'
require 'json'
require 'fileutils'

require 'test_helpers/sandbox'
require 'test_helpers/capture'

module ApplicationTests
  class ExporterTest < SandboxTest

    include TestHelpers::Capture

    def setup
      build_app
      basic_info
    end

    def teardown
      teardown_app
    end

    def test_exports
      variable_csv = <<-CSV
folder,id,display_name,description,type,units,domain,labels,calculation
"",age_at_visit,Age at Visit,Age at time of visit.,numeric,years,"",age_at_visit,""
"",gender,Gender,Gender as reported by Parent Cohort,choices,"",gdomain,gender,""
      CSV

      domain_csv = <<-CSV
folder,domain_id,value,display_name,description
"",gdomain,m,Male,""
"",gdomain,f,Female,""
      CSV

      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['export'] }
      end

      assert File.directory?(File.join(app_path, 'dd'))
      assert_equal variable_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'variables.csv'))
      assert_equal domain_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'domains.csv'))
      assert_match "dd/1.0.0/variables.csv", output
      assert_match "dd/1.0.0/domains.csv", output
    end
  end
end
