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
          @stratification_variable.domain.options.collect do |option|
            filtered_subjects = filter_and_sort_subjects_by_option(option)
            next if filtered_subjects.size == 0

            data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
              array = filtered_subjects.send(quartile).collect(&@variable.id.to_sym)
              array_statistics(array)
            end

            { name: option.display_name, data: data }
          end.compact
        end

        private

        def filter_and_sort_subjects_by_option(option)
          begin
            @subjects.select do |s|
              s._visit == option.value and s.send(@variable.id) != nil and s.send(@chart_variable.id) != nil
            end.sort_by(&@chart_variable.id.to_sym)
          rescue
            []
          end
        end

        def array_statistics(array)
          {      y: (array.mean.round(1) rescue 0.0),
            stddev: ("%0.1f" % array.standard_deviation rescue ''),
            median: ("%0.1f" % array.median rescue ''),
               min: ("%0.1f" % array.min rescue ''),
               max: ("%0.1f" % array.max rescue ''),
                 n: array.n }
        end

      end
    end
  end
end
