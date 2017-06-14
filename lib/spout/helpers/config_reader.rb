# frozen_string_literal: true

require "yaml"

module Spout
  module Helpers
    # Loads the .spout.yml configuration file.
    class ConfigReader
      attr_reader :slug, :visit, :charts, :webservers

      def initialize
        @slug = ""
        @visit = ""
        @charts = []
        @webservers = []
        parse_yaml_file
      end

      def parse_yaml_file
        spout_config = YAML.load_file(".spout.yml")

        if spout_config.is_a?(Hash)
          @slug = spout_config["slug"].to_s.strip
          @visit = spout_config["visit"].to_s.strip

          @charts = \
            if spout_config["charts"].is_a?(Array)
              spout_config["charts"].select { |c| c.is_a?(Hash) }
            else
              []
            end

          @webservers = \
            if spout_config["webservers"].is_a?(Array)
              spout_config["webservers"].select { |c| c.is_a?(Hash) }
            else
              []
            end
        else
          puts "The YAML file needs to be in the following format:"
          puts "---\nvisit: visit_variable_name\ncharts:\n- chart: age_variable_name\n  title: Age\n- chart: gender_variable_name\n  title: Gender\n- chart: race_variable_name\n  title: Race\n"
        end
      end
    end
  end
end
