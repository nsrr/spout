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
      remove_basic_info
      teardown_app
    end

    def test_exports
      variable_csv = "folder,id,display_name,description,type,units,domain,labels,calculation\n\"\",age_at_visit,Age at Visit,Age at time of visit.,numeric,years,\"\",age_at_visit,\"\"\n\"\",gender,Gender,Gender as reported by Parent Cohort,choices,\"\",gdomain,gender,\"\"\n"
      domain_csv = "folder,domain_id,value,display_name,description\n\"\",gdomain,m,Male,\"\"\n\"\",gdomain,f,Female,\"\"\n"

      output, error = util_capture do
        Dir.chdir(app_path) { Spout.launch ['export'] }
      end

      puts File.read(File.join(app_path, 'dd', '1.0.0', 'variables.csv'))
      puts File.read(File.join(app_path, 'dd', '1.0.0', 'domains.csv'))

      assert File.directory?(File.join(app_path, 'dd'))
      assert_equal ["age_at_visit", "gender"].sort, Dir.glob(File.join(app_path, 'variables', '**', '*.json')).collect{|s| s.gsub(/^(.*)\/|\.json$/, '')}.sort
      assert_equal variable_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'variables.csv'))
      assert_equal domain_csv, File.read(File.join(app_path, 'dd', '1.0.0', 'domains.csv'))
      assert_match "dd/1.0.0/variables.csv", output
      assert_match "dd/1.0.0/domains.csv", output
    end
  end
end
