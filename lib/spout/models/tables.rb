# frozen_string_literal: true

require "spout/models/tables/default"
require "spout/models/tables/numeric_vs_choices"
require "spout/models/tables/choices_vs_choices"
require "spout/models/tables/numeric_vs_numeric"
require "spout/models/tables/choices_vs_numeric"

module Spout
  module Models
    module Tables
      DEFAULT_CLASS = Spout::Models::Tables::Default
      GRAPHABLE_CLASSES = {
        "numeric_vs_choices" => Spout::Models::Tables::NumericVsChoices,
        "choices_vs_choices" => Spout::Models::Tables::ChoicesVsChoices,
        "numeric_vs_numeric" => Spout::Models::Tables::NumericVsNumeric,
        "choices_vs_numeric" => Spout::Models::Tables::ChoicesVsNumeric
      }

      def self.for(variable, chart_variable, subjects, subtitle, totals: true)
        table_type = get_table_type(variable, chart_variable)
        (GRAPHABLE_CLASSES[table_type] || DEFAULT_CLASS).new(variable, chart_variable, subjects, subtitle, totals)
      end

      def self.get_table_type(variable, chart_variable)
        "#{variable_to_table_type(variable)}_vs_#{variable_to_table_type(chart_variable)}"
      end

      # Identical to graphables, TODO: Refactor
      def self.variable_to_table_type(variable)
        variable_type = (variable ? variable.type : nil)
        case variable_type
        when "numeric", "integer"
          "numeric"
        else
          variable_type
        end
      end
    end
  end
end
