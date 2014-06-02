require 'tmpdir'

module TestHelpers
  module Paths
    def app_template_path
      File.join Dir.tmpdir, 'app_template'
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
      File.open("#{app_path}/#{path}", 'w') do |f|
        f.puts contents
      end
    end

    def delete_app_file(file)
      File.delete("#{app_path}/#{file}")
    end
  end
end

require 'test_helper'
class SpoutAppTestCase < Test::Unit::TestCase
  include TestHelpers::Paths
  include TestHelpers::Generation
end

# Create a scope and build a fixture spout app
Module.new do
  extend TestHelpers::Paths

  # Build a spout app
  FileUtils.rm_rf(app_template_path)
  FileUtils.mkdir(app_template_path)

  Spout.launch(['new', app_template_path, '--skip-gemfile'])
end
