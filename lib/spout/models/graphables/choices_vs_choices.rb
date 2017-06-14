# frozen_string_literal: true

require "spout/models/graphables/default"

module Spout
  module Models
    module Graphables
      class ChoicesVsChoices < Spout::Models::Graphables::Default
        def categories
          filtered_domain_options(@chart_variable).collect(&:display_name)
        end

        def units
          "percent"
        end

        def series
          filtered_domain_options(@variable).collect do |option|
            filtered_subjects = @subjects.select{ |s| s.send(@variable.id) == option.value }
            data = filtered_domain_options(@chart_variable).collect do |chart_option|
              filtered_subjects.select{ |s| s.send(@chart_variable.id) == chart_option.value }.count
            end
            { name: option.display_name, data: data }
          end
        end

        def stacking
          "percent"
        end
      end
    end
  end
end
