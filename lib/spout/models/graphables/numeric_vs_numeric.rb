require 'spout/models/graphables/default'
require 'spout/helpers/array_statistics'

module Spout
  module Models
    module Graphables
      class NumericVsNumeric < Spout::Models::Graphables::Default

        def categories
          ["Quartile One", "Quartile Two", "Quartile Three", "Quartile Four"]
        end

        def units
          @variable.units
        end

        def series
          series_result = []
          @stratification_variable.domain.options.each do |option|
            data = []

            filtered_subjects = @subjects.select{ |s| s._visit == option.value and s.send(@variable.id) != nil and s.send(@chart_variable.id) != nil }.sort_by(&@chart_variable.id.to_sym) rescue filtered_subjects = []

            [:quartile_one, :quartile_two, :quartile_three, :quartile_four].each do |quartile|
              array = filtered_subjects.send(quartile).collect(&@variable.id.to_sym)
              data << {         y: (array.mean.round(1) rescue 0.0),
                           stddev: ("%0.1f" % array.standard_deviation rescue ''),
                           median: ("%0.1f" % array.median rescue ''),
                              min: ("%0.1f" % array.min rescue ''),
                              max: ("%0.1f" % array.max rescue ''),
                                n: array.n }
            end

            series_result << { name: option.display_name, data: data } unless filtered_subjects.size == 0
          end
          series_result
        end

      end
    end
  end
end
