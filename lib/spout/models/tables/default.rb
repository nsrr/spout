require 'spout/models/variable'
require 'spout/helpers/table_formatting'

module Spout
  module Models
    module Tables
      class Default

        attr_reader :variable, :chart_variable, :subjects, :subtitle

        def initialize(variable, chart_variable, subjects, subtitle)
          @variable = variable
          @chart_variable = chart_variable
          @subjects = subjects
          @subtitle = subtitle

          @filtered_subjects = @subjects.select{ |s| s.send(@chart_variable.id) != nil } rescue @filtered_subjects = []
          @filtered_both_variables_subjects = subjects.select{ |s| s.send(@variable.id) != nil and s.send(@chart_variable.id) != nil }.sort_by(&@chart_variable.id.to_sym) rescue @filtered_both_variables_subjects = []

          @values = @filtered_subjects.collect(&@variable.id.to_sym).uniq rescue @values = []

          @values_unique = @values.uniq

          @values_both_variables = @filtered_both_variables_subjects.collect(&@variable.id.to_sym).uniq rescue @values_both_variables = []
          @values_both_variables_unique = @values_both_variables.uniq
        end

        def to_hash
          if valid?
            { title: title, subtitle: @subtitle, headers: headers, footers: footers, rows: rows }
          else
            nil
          end
        end

        # TODO: Same as graphables/default.rb REFACTOR
        def valid?
          if @variable == nil or @chart_variable == nil or @values == []
            false
          elsif @variable.type == 'choices' and @variable.domain.options == []
            false
          elsif @chart_variable.type == 'choices' and @chart_variable.domain.options == []
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
            o.missing != true or (o.missing == true and @values_unique.include?(o.value))
          end
        end

        def filtered_both_variables_domain_options(variable)
          variable.domain.options.select do |o|
            o.missing != true or (o.missing == true and @values_both_variables_unique.include?(o.value))
          end
        end

      end
    end
  end
end
