# frozen_string_literal: true

require 'colorize'
require 'date'
require 'erb'
require 'fileutils'

TEMPLATES_DIRECTORY = File.expand_path('../../templates', __FILE__)

module Spout
  module Commands
    # Generates folder and file structure for a new spout data dictionary.
    class ProjectGenerator
      def initialize(argv)
        generate_folder_structure!(argv)
      end

      def generate_folder_structure!(argv)
        skip_gemfile = !argv.delete('--skip-gemfile').nil?
        @project_name = argv[1].to_s.strip
        @full_path = File.join(@project_name)
        usage = <<-EOT

Usage: spout new FOLDER

The FOLDER must be empty or new.

EOT
        if @full_path == '' || (Dir.exist?(@full_path) && (Dir.entries(@full_path) & ['.gitignore', '.ruby-version', '.travis.yml', 'Gemfile', 'Rakefile', 'domains', 'variables', 'test']).size > 0)
          puts usage
          exit(0)
        end
        FileUtils.mkpath(@full_path)
        copy_file 'gitignore', '.gitignore'
        copy_file 'ruby-version', '.ruby-version'
        copy_file 'travis.yml', '.travis.yml'
        evaluate_file 'spout.yml.erb', '.spout.yml'
        evaluate_file 'CHANGELOG.md.erb', 'CHANGELOG.md'
        copy_file 'Gemfile'
        copy_file 'Rakefile'
        evaluate_file 'README.md.erb', 'README.md'
        copy_file 'VERSION'
        directory 'domains'
        copy_file 'keep', 'domains/.keep'
        directory 'variables'
        copy_file 'keep', 'variables/.keep'
        directory 'forms'
        copy_file 'keep', 'forms/.keep'
        directory 'test'
        copy_file 'test/dictionary_test.rb'
        copy_file 'test/test_helper.rb'
        return if skip_gemfile
        puts '         run'.colorize(:green) + '  bundle install'.colorize(:light_cyan)
        Dir.chdir(@full_path)
        system 'bundle install'
      end

      private

      def copy_file(template_file, file_name = '')
        file_name = template_file if file_name == ''
        file_path = File.join(@full_path, file_name)
        template_file_path = File.join(TEMPLATES_DIRECTORY, template_file)
        puts '      create'.colorize(:green) + "  #{file_name}"
        FileUtils.copy(template_file_path, file_path)
      end

      def evaluate_file(template_file, file_name)
        template_file_path = File.join(TEMPLATES_DIRECTORY, template_file)
        template = ERB.new(File.read(template_file_path))
        file_path = File.join(@full_path, file_name)
        file_out = File.new(file_path, 'w')
        file_out.syswrite(template.result(binding))
        puts '      create'.colorize(:green) + "  #{file_name}"
      ensure
        file_out.close if file_out
      end

      def directory(directory_name)
        directory_path = File.join(@full_path, directory_name)
        puts '      create'.colorize(:green) + "  #{directory_name}"
        FileUtils.mkpath(directory_path)
      end
    end
  end
end
