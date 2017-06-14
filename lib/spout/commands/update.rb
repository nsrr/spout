# frozen_string_literal: true

require "colorize"
require "spout/helpers/json_request"
require "spout/helpers/framework"

module Spout
  module Commands
    # Command to check if there is an updated version of the gem available.
    class Update
      include Spout::Helpers::Framework

      class << self
        def start(*args)
          new(*args).start
        end
      end

      def initialize(argv)
        @full_path = File.join(".")
      end

      def start
        (json, _status) = Spout::Helpers::JsonRequest.get("https://rubygems.org/api/v1/gems/spout.json")
        if json
          if json["version"] == Spout::VERSION::STRING
            puts "The spout gem is " + "up-to-date".colorize(:green) + "!"
            check_framework if File.exist?("Gemfile")
          else
            puts "A newer version (v#{json['version']}) is available!\n\n"
            if File.exist?("Gemfile")
              puts "Add the following to your Gemfile and run " + "bundle update".colorize(:green) + ".\n\n"
              puts "  gem \"spout\", \"~> #{json['version']}\"\n".colorize(:white)
            else
              puts "Type the following command to update:\n\n"
              puts "  gem install spout --no-document".colorize(:white) + "\n\n"
            end
          end
        else
          puts "Unable to connect to RubyGems.org. Please try again later."
        end
      end

      def check_framework
        check_gitignore_file
        check_ruby_version
        check_file_presence
        check_folder_presence
        check_test_folder
      end

      def check_gitignore_file
        if File.exist?(".gitignore")
          lines = IO.readlines(".gitignore").collect(&:strip)
          addables = ["/coverage", "/csvs", "/exports", "/graphs"]
          removables = ["/dd", "/images"]
          unless ((removables & lines) | (addables - lines)).empty?
            puts "File: " + ".gitignore".colorize(:white)
            puts "----------------"
            (removables & lines).each do |removable|
              puts "REMOVE LINE ".colorize(:red) + removable.colorize(:white)
            end
            (addables - lines).each do |addable|
              puts "   ADD LINE ".colorize(:green) + addable.colorize(:white)
            end
            puts
          end
        else
          copy_file "gitignore", ".gitignore"
        end
      end

      def check_ruby_version
        if File.exist?(".ruby-version")
          lines = IO.readlines(".ruby-version").collect(&:strip)
          template_lines = IO.readlines(File.expand_path("../../templates/ruby-version", __FILE__)).collect(&:strip)
          if template_lines.first != lines.first
            puts "File: " + ".ruby-version".colorize(:white)
            puts "-------------------"
            print "Update Ruby from " + lines.first.to_s.colorize(:red)
            print " to " + template_lines.first.to_s.colorize(:green)
            puts "\n\n"
          end
        else
          copy_file "ruby-version", ".ruby-version"
        end
      end

      def check_file_presence
        @project_name = File.basename(Dir.pwd)
        evaluate_file "CHANGELOG.md.erb", "CHANGELOG.md" unless File.exist?("CHANGELOG.md")
        evaluate_file "README.md.erb", "README.md" unless File.exist?("README.md")
        copy_file "VERSION" unless File.exist?("VERSION")
      end

      def check_folder_presence
        folders = %w(domains forms variables).reject { |f| Dir.exist?(f) }
        folders.each do |folder|
          directory folder
          copy_file "keep", "#{folder}/.keep"
        end
      end

      def check_test_folder
        return if Dir.exist?("test")
        directory "test"
        copy_file "test/dictionary_test.rb"
        copy_file "test/test_helper.rb"
      end
    end
  end
end
