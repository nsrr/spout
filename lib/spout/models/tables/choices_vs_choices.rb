# frozen_string_literal: true

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
          header_row = [''] + filtered_domain_options(@chart_variable).collect(&:display_name)
          if @totals
            header_row += ['Total']
          end
          [header_row]
        end

        def footers
          total_values = filtered_domain_options(@chart_variable).collect do |option|
            total_count = @filtered_subjects.count { |s| s.send(@chart_variable.id) == option.value }
            { text: (Spout::Helpers::TableFormatting.format_number(total_count, :count)), style: 'font-weight:bold' }
          end
          footer_row = [{ text: 'Total', style: 'font-weight:bold' }] + total_values
          if @totals
            footer_row += [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count, :count), style: 'font-weight:bold' }]
          end
          [footer_row]
        end

        def rows
          rows_result = filtered_domain_options(@variable).collect do |option|
            row_subjects = @filtered_subjects.select { |s| s.send(@variable.id) == option.value }
            row_cells = filtered_domain_options(@chart_variable).collect do |chart_option|
              count = row_subjects.count { |s| s.send(@chart_variable.id) == chart_option.value }
              count > 0 ? Spout::Helpers::TableFormatting.format_number(count, :count) : { text: '-', class: 'text-muted' }
            end

            row = [option.display_name] + row_cells

            if @totals
              total = row_subjects.count
              row += [total == 0 ? { text: '-', class: 'text-muted' } : { text: Spout::Helpers::TableFormatting.format_number(total, :count), style: 'font-weight:bold' }]
            end
            row
          end

          if @filtered_subjects.count { |s| s.send(@variable.id).is_a?(Spout::Models::Empty) } > 0
            unknown_values = filtered_domain_options(@chart_variable).collect do |chart_option|
              { text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count { |s| s.send(@chart_variable.id) == chart_option.value && s.send(@variable.id).is_a?(Spout::Models::Empty) }, :count), class: 'text-muted' }
            end
            unknown_row = [{ text: 'Unknown', class: 'text-muted' }] + unknown_values
            if @totals
              unknown_row += [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count { |s| s.send(@variable.id).is_a?(Spout::Models::Empty) }, :count), style: 'font-weight:bold', class: 'text-muted' }]
            end
            rows_result << unknown_row
          end
          rows_result
        end
      end
    end
  end
end
