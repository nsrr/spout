# frozen_string_literal: true

require "spout/models/graphables/default"
require "spout/models/graphables/histogram"
require "spout/models/graphables/numeric_vs_choices"
require "spout/models/graphables/choices_vs_choices"
require "spout/models/graphables/numeric_vs_numeric"
require "spout/models/graphables/choices_vs_numeric"

module Spout
  module Models
    module Graphables
      DEFAULT_CLASS = Spout::Models::Graphables::Default
      GRAPHABLE_CLASSES = {
        "histogram" =>          Spout::Models::Graphables::Histogram,
        "numeric_vs_choices" => Spout::Models::Graphables::NumericVsChoices,
        "choices_vs_choices" => Spout::Models::Graphables::ChoicesVsChoices,
        "numeric_vs_numeric" => Spout::Models::Graphables::NumericVsNumeric,
        "choices_vs_numeric" => Spout::Models::Graphables::ChoicesVsNumeric
      }

      def self.for(variable, chart_variable, stratification_variable, subjects)
        graph_type = get_graph_type(variable, chart_variable, stratification_variable)
        (GRAPHABLE_CLASSES[graph_type] || DEFAULT_CLASS).new(variable, chart_variable, stratification_variable, subjects)
      end

      def self.get_graph_type(variable, chart_variable, stratification_variable)
        if stratification_variable.nil?
          "histogram"
        else
          "#{variable_to_graph_type(variable)}_vs_#{variable_to_graph_type(chart_variable)}"
        end
      end

      def self.variable_to_graph_type(variable)
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
