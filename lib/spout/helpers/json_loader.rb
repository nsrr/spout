# frozen_string_literal: true

require "json"

module Spout
  module Helpers
    class JsonLoader
      def self.get_json(file_name, file_type)
        file = Dir.glob("#{file_type.to_s.downcase}s/**/#{file_name.to_s.downcase}.json", File::FNM_CASEFOLD).first
        JSON.parse(File.read(file, encoding: "utf-8"))
      rescue => e
        puts "JsonLoader Warning".red
        puts e.to_s.white
        nil
      end

      def self.get_variable(variable_name)
        get_json(variable_name, "variable")
      end
    end
  end
end
