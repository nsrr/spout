# frozen_string_literal: true

require "fileutils"

require "spout/helpers/framework"

module Spout
  module Commands
    # Generates folder and file structure for a new spout data dictionary.
    class ProjectGenerator
      include Spout::Helpers::Framework

      def initialize(argv)
        generate_folder_structure!(argv)
      end

      def generate_folder_structure!(argv)
        skip_gemfile = !argv.delete("--skip-gemfile").nil?
        @project_name = argv[1].to_s.strip
        @full_path = File.join(@project_name)
        usage = <<-EOT

Usage: spout new FOLDER

The FOLDER must be empty or new.

EOT
        if @full_path == "" || (Dir.exist?(@full_path) && (Dir.entries(@full_path) & [".gitignore", ".ruby-version", ".travis.yml", "Gemfile", "gems.rb", "domains", "variables", "test"]).size > 0)
          puts usage
          exit(0)
        end
        FileUtils.mkpath(@full_path)
        copy_file "gitignore", ".gitignore"
        copy_file "ruby-version", ".ruby-version"
        copy_file "travis.yml", ".travis.yml"
        evaluate_file "spout.yml.erb", ".spout.yml"
        evaluate_file "CHANGELOG.md.erb", "CHANGELOG.md"
        copy_file "gems.rb"
        evaluate_file "README.md.erb", "README.md"
        copy_file "VERSION"
        directory "domains"
        copy_file "keep", "domains/.keep"
        directory "variables"
        copy_file "keep", "variables/.keep"
        directory "forms"
        copy_file "keep", "forms/.keep"
        directory "test"
        copy_file "test/dictionary_test.rb"
        copy_file "test/test_helper.rb"
        return if skip_gemfile
        puts "         run".green + "  bundle install".cyan
        Dir.chdir(@full_path)
        system "bundle install"
      end
    end
  end
end
