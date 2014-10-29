require 'spout/models/graphables/default'
require 'spout/helpers/array_statistics'

module Spout
  module Models
    module Graphables
      class ChoicesVsNumeric < Spout::Models::Graphables::Default

        def categories
          filtered_subjects = @subjects.select{ |s| s.send(@variable.id) != nil and s.send(@chart_variable.id) != nil }.sort_by(&@chart_variable.id.to_sym) rescue filtered_subjects = []

          [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            quartile = filtered_subjects.send(quartile).collect(&@chart_variable.id.to_sym)
            "#{quartile.min} to #{quartile.max}"
          end
        end

        def units
          'percent'
        end

        def series
          series_result = []
          filtered_subjects = @subjects.select{ |s| s.send(@variable.id) != nil and s.send(@chart_variable.id) != nil }.sort_by(&@chart_variable.id.to_sym) rescue filtered_subjects = []

          filtered_domain_options(@variable).each do |option|
            data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
              filtered_subjects.send(quartile).select{ |s| s.send(@variable.id) == option.value }.count
            end
            series_result << { name: option.display_name, data: data } unless filtered_subjects.size == 0
          end
          series_result
        end

        def stacking
          'percent'
        end

      end
    end
  end
end
