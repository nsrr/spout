require 'spout/models/graphables'

module Spout
  module Models
    class Graph

      attr_accessor :chart_variable, :subjects, :variable, :stratification_variable

      def initialize(chart_type, subjects, variable, stratification_variable)
        chart_variable = Spout::Models::Variable.find_by_id(chart_type)
        @graphable = Spout::Models::Graphables.for(variable, chart_variable, stratification_variable, subjects)
      end

      def to_hash
        @graphable.to_hash
      end

      def title
        @graphable.title
      end

      def subtitle
        @graphable.subtitle
      end

      def categories
        @graphable.categories
      end

      def units
        @graphable.units
      end

      def series
        @graphable.series
      end

      def stacking
        @graphable.stacking
      end

      def x_axis_title
        @graphable.x_axis_title
      end

    end
  end
end
