# frozen_string_literal: true

require "spout/models/graphables/default"
require "spout/helpers/array_statistics"

module Spout
  module Models
    module Graphables
      class ChoicesVsNumeric < Spout::Models::Graphables::Default
        def categories
          filtered_subjects = filter_and_sort_subjects

          return [] if filtered_subjects.size == 0

          [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            quartile = filtered_subjects.send(quartile).collect(&@chart_variable.id.to_sym)
            "#{quartile.min} to #{quartile.max}"
          end
        end

        def units
          "percent"
        end

        def series
          filtered_subjects = filter_and_sort_subjects

          return [] if filtered_subjects.size == 0

          filtered_domain_options(@variable).collect do |option|
            data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
              filtered_subjects.send(quartile).select{ |s| s.send(@variable.id) == option.value }.count
            end
            { name: option.display_name, data: data }
          end
        end

        def stacking
          "percent"
        end

        private

        def filter_and_sort_subjects
          @filter_and_sort_subjects ||= begin
            @subjects.select do |s|
              s.send(@variable.id) != nil and s.send(@chart_variable.id) != nil
            end.sort_by(&@chart_variable.id.to_sym)
          rescue
            []
          end
        end
      end
    end
  end
end
