# frozen_string_literal: true

require "spout/models/graphables/default"

module Spout
  module Models
    module Graphables
      # Generates data for variable histograms
      class Histogram < Spout::Models::Graphables::Default
        def title
          @variable.display_name
        end

        def categories
          if @variable.type == "choices"
            filtered_domain_options(@variable).collect(&:display_name)
          else
            @buckets.collect(&:display_name)
          end
        end

        def units
          "Subjects"
        end

        def series
          @chart_variable.domain.options.collect do |option|
            visit_subjects = @subjects.select{ |s| s.send(@chart_variable.id) == option.value && !s.send(@variable.id).nil? && !s.send(@variable.id).is_a?(Spout::Models::Empty) } rescue visit_subjects = []
            visit_subject_values = visit_subjects.collect(&@variable.id.to_sym).sort # rescue visit_subject_values = []
            next unless visit_subject_values.size > 0

            data = []

            if @variable.type == "choices"
              data = filtered_domain_options(@variable).collect do |o|
                visit_subject_values.select { |v| v == o.value }.count
              end
            else
              visit_subject_values.group_by { |v| get_bucket(v) }.each do |key, values|
                data[categories.index(key)] = values.count if categories.index(key)
              end
            end

            { name: option.display_name, data: data }
          end.compact
        end

        def x_axis_title
          @variable.units
        end
      end
    end
  end
end
