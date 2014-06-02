require 'temp_app_loader'

module ApplicationTests
  class ImporterTest < SpoutAppTestCase

    def setup
      build_app
      app_file 'variables-import.csv', <<-CSV
folder,id,display_name,description,type,domain,units,calculation,labels
Demographics,gender,Gender,Gender Description,choices,gdomain,,,gender,
      CSV
      app_file 'domains-import.csv', <<-CSV
folder,domain_id,display_name,description,value
,gender,Male,,m
,gender,Female,,f
      CSV
    end

    def teardown
      teardown_app
    end

    def test_variable_imports
      Dir.chdir(app_path) { Spout.launch ['import', 'variables-import.csv'] }
      assert_equal 1, Dir.glob(File.join(app_path, 'variables', '**', '*.json')).count
    end

    def test_domain_imports
      Dir.chdir(app_path) { Spout.launch ['import', 'domains-import.csv', '--domains'] }
      assert_equal 1, Dir.glob(File.join(app_path, 'domains', '**', '*.json')).count
    end
  end
end
