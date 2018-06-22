# frozen_string_literal: true

require "date"
require "erb"
require "fileutils"

require "spout/helpers/color"

TEMPLATES_DIRECTORY = File.expand_path("../../templates", __FILE__)

module Spout
  module Helpers
    # Helpers to generate and update Spout dictionary framework.
    module Framework
      def copy_file(template_file, file_name = "")
        file_name = template_file if file_name == ""
        file_path = File.join(@full_path, file_name)
        template_file_path = File.join(TEMPLATES_DIRECTORY, template_file)
        puts "      create".green + "  #{file_name}"
        FileUtils.copy(template_file_path, file_path)
      end

      def evaluate_file(template_file, file_name)
        template_file_path = File.join(TEMPLATES_DIRECTORY, template_file)
        template = ERB.new(File.read(template_file_path))
        file_path = File.join(@full_path, file_name)
        file_out = File.new(file_path, "w")
        file_out.syswrite(template.result(binding))
        puts "      create".green + "  #{file_name}"
      ensure
        file_out.close if file_out
      end

      def directory(directory_name)
        directory_path = File.join(@full_path, directory_name)
        puts "      create".green + "  #{directory_name}"
        FileUtils.mkpath(directory_path)
      end
    end
  end
end
