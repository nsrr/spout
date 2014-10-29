require 'spout/models/tables/default'
require 'spout/helpers/array_statistics'

module Spout
  module Models
    module Tables
      class NumericVsChoices < Spout::Models::Tables::Default

        def title
          "#{@chart_variable.display_name} vs #{@variable.display_name}"
        end

        def headers
          [
            [""] + Spout::Helpers::ArrayStatistics::calculations.collect{|calculation_label, calculation_method| calculation_label} + ["Total"]
          ]
        end

        def footers
          total_values = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
            total_count = @filtered_subjects.collect(&@variable.id.to_sym).send(calculation_method)
            { text: Spout::Helpers::TableFormatting::format_number(total_count, calculation_type, calculation_format), style: "font-weight:bold" }
          end

          [
            [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: Spout::Helpers::TableFormatting::format_number(@filtered_subjects.count, :count), style: 'font-weight:bold'}]
          ]
        end

        def rows
          filtered_domain_options(@chart_variable).collect do |option|
            row_subjects = @filtered_subjects.select{ |s| s.send(@chart_variable.id) == option.value }

            row_cells = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
              count = row_subjects.collect(&@variable.id.to_sym).send(calculation_method)
              (count == 0 && calculation_method == :count) ? { text: '-', class: 'text-muted' } : Spout::Helpers::TableFormatting::format_number(count, calculation_type, calculation_format)
            end

            [option.display_name] + row_cells + [{ text: Spout::Helpers::TableFormatting::format_number(row_subjects.count, :count), style: 'font-weight:bold'}]
          end
        end


      end
    end
  end
end
