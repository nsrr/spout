require 'yaml'

module Spout
  module Helpers
    class ConfigReader

      attr_reader :slug, :visit, :charts


      def initialize
        @slug = ''
        @visit = ''
        @charts = []
        parse_yaml_file
      end

      def parse_yaml_file
        spout_config = YAML.load_file('.spout.yml')

        if spout_config.kind_of?(Hash)
          @slug = spout_config['slug'].to_s.strip
          @visit = spout_config['visit'].to_s.strip

          @charts = if spout_config['charts'].kind_of?(Array)
            spout_config['charts'].select{|c| c.kind_of?(Hash)}
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
