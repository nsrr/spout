require 'spout/models/tables/default'

module Spout
  module Models
    module Tables
      # Generates a table of
      class ChoicesVsChoices < Spout::Models::Tables::Default
        def title
          "#{@variable.display_name} vs #{@chart_variable.display_name}"
        end

        def headers
          [[''] + filtered_domain_options(@chart_variable).collect(&:display_name) + ['Total']]
        end

        def footers
          total_values = filtered_domain_options(@chart_variable).collect do |option|
            total_count = @filtered_subjects.count { |s| s.send(@chart_variable.id) == option.value }
            { text: (Spout::Helpers::TableFormatting.format_number(total_count, :count)), style: 'font-weight:bold' }
          end
          [
            [{ text: 'Total', style: 'font-weight:bold' }] + total_values + [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count, :count), style: 'font-weight:bold' }]
          ]
        end

        def rows
          rows_result = filtered_domain_options(@variable).collect do |option|
            row_subjects = @filtered_subjects.select { |s| s.send(@variable.id) == option.value }
            row_cells = filtered_domain_options(@chart_variable).collect do |chart_option|
              count = row_subjects.count { |s| s.send(@chart_variable.id) == chart_option.value }
              count > 0 ? Spout::Helpers::TableFormatting.format_number(count, :count) : { text: '-', class: 'text-muted' }
            end

            total = row_subjects.count

            [option.display_name] + row_cells + [total == 0 ? { text: '-', class: 'text-muted' } : { text: Spout::Helpers::TableFormatting.format_number(total, :count), style: 'font-weight:bold' }]
          end

          if @filtered_subjects.count { |s| s.send(@variable.id).is_a?(Spout::Models::Empty) } > 0
            unknown_values = filtered_domain_options(@chart_variable).collect do |chart_option|
              { text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count { |s| s.send(@chart_variable.id) == chart_option.value && s.send(@variable.id).is_a?(Spout::Models::Empty) }, :count), class: 'text-muted' }
            end
            rows_result << [{ text: 'Unknown', class: 'text-muted'}] + unknown_values + [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count { |s| s.send(@variable.id).is_a?(Spout::Models::Empty) }, :count), style: 'font-weight:bold', class: 'text-muted' }]
          end
          rows_result
        end
      end
    end
  end
end
