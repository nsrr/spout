require "tmpdir"

module TestHelpers
  module Paths
    def app_template_path
      File.join Dir.tmpdir, "app_template"
    end

    def tmp_path(*args)
      @tmp_path ||= File.realpath(Dir.mktmpdir)
      File.join(@tmp_path, *args)
    end

    def app_path(*args)
      tmp_path(*%w[app] + args)
    end
  end

  module Generation
    def build_app
      FileUtils.rm_rf(app_path)
      FileUtils.cp_r(app_template_path, app_path)
    end

    def teardown_app
      FileUtils.rm_rf(tmp_path)
      @tmp_path = nil
    end

    def app_file(path, contents)
      FileUtils.mkdir_p File.dirname("#{app_path}/#{path}")
      File.open("#{app_path}/#{path}", "w") do |f|
        f.puts contents
      end
    end

    def delete_app_file(file)
      File.delete("#{app_path}/#{file}")
    end

    def read_index_file(type = "index")
      File.read(File.join(app_path, "coverage", "#{type}.html"))
    rescue
      nil
    end
  end

  module Fixtures
    def basic_info
      app_file ".spout.yml", <<-YML
# slug: myrepo
visit: visit
charts:
  - chart: age_at_visit
    title: Age
  - chart: gender
    title: Gender
      YML
      app_file "variables/age_at_visit.json", <<-JSON
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
      app_file "variables/gender.json", <<-JSON
        {
          "id": "gender",
          "display_name": "Gender",
          "description": "Gender as reported by Parent Cohort",
          "type": "choices",
          "domain": "gdomain",
          "labels": [
            "gender"
          ],
          "commonly_used": true,
          "forms": [
            "intake_questionnaire"
          ]
        }
      JSON
      app_file "domains/gdomain.json", <<-JSON
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
          },
          {
            "value": "r",
            "display_name": "Refused to Answer",
            "description": "",
            "missing": true
          }
        ]
      JSON
      app_file "forms/intake_questionnaire.json", <<-JSON
        {
          "id": "intake_questionnaire",
          "display_name": "Intake Questionnaire at Baseline Visit",
          "code_book": "Baseline-Visit-Intake-Questionnaire.pdf"
        }
      JSON
      app_file "csvs/1.0.0/dataset.csv", <<-CSV
visit,age_at_visit,gender
1,30,m
1,40,m
1,42,m
1,28,m
1,48,m
1,22,f
1,53,f
1,30,f
1,44,f
1,34,f
2,45,m
2,47,m
2,33,m
2,53,m
2,27,f
2,35,f
2,49,f
2,39,f
      CSV
    end

    def remove_basic_info
      delete_app_file ".spout.yml"
      delete_app_file "variables/age_at_visit.json"
      delete_app_file "variables/gender.json"
      delete_app_file "domains/gdomain.json"
      delete_app_file "csvs/1.0.0/dataset.csv"
    end

    def create_visit_variable_and_domain
      app_file "variables/visit.json", <<-JSON
        {
          "id": "visit",
          "display_name": "Visit",
          "description": "Visit Number",
          "type": "choices",
          "domain": "vdomain",
          "labels": [
            "visit"
          ],
          "commonly_used": true
        }
      JSON
      app_file "domains/vdomain.json", <<-JSON
        [
          {
            "value": "1",
            "display_name": "Visit One",
            "description": ""
          },
          {
            "value": "2",
            "display_name": "Visit Two",
            "description": ""
          }
        ]
      JSON
    end

    def remove_visit_variable_and_domain
      delete_app_file "variables/visit.json"
      delete_app_file "domains/vdomain.json"
    end
  end
end

require "test_helper"
require "fileutils"
class SandboxTest < Minitest::Test
  include TestHelpers::Paths
  include TestHelpers::Generation
  include TestHelpers::Fixtures
end

# Create a scope and build a fixture spout app
Module.new do
  extend TestHelpers::Paths

  # Build a spout app
  FileUtils.rm_rf(app_template_path)
  FileUtils.mkdir(app_template_path)

  Spout.launch(["new", app_template_path, "--skip-gemfile"])
end
