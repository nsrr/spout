# frozen_string_literal: true

require "spout/models/variable"
require "spout/helpers/table_formatting"

module Spout
  module Models
    module Tables
      class Default
        attr_reader :variable, :chart_variable, :subjects, :subtitle, :totals

        def initialize(variable, chart_variable, subjects, subtitle, totals)
          @variable = variable
          @chart_variable = chart_variable
          @subtitle = subtitle
          @totals = totals
          begin
            @filtered_subjects = subjects.reject { |s| s.send(@chart_variable.id).is_a?(Spout::Models::Empty) }.sort_by(&@chart_variable.id.to_sym)
          rescue
            @filtered_subjects = []
          end
          begin
            @values_unique = @filtered_subjects.collect(&@variable.id.to_sym).uniq
          rescue
            @values_unique = []
          end
        end

        def to_hash
          { title: title, subtitle: @subtitle, headers: headers, footers: footers, rows: rows } if valid?
        end

        # TODO: Same as graphables/default.rb REFACTOR
        def valid?
          if @variable.nil? || @chart_variable.nil? || @values_unique == []
            false
          elsif @variable.type == "choices" && @variable.domain.options == []
            false
          elsif @chart_variable.type == "choices" && @chart_variable.domain.options == []
            false
          else
            true
          end
        end

        def title
          ""
        end

        def headers
          []
        end

        def footers
          []
        end

        def rows
          []
        end

        private

        # Returns variable options that are either:
        # a) are not missing codes
        # b) or are marked as missing codes but represented in the dataset
        def filtered_domain_options(variable)
          variable.domain.options.select do |o|
            o.missing != true || (o.missing == true && @values_unique.include?(o.value))
          end
        end
      end
    end
  end
end
