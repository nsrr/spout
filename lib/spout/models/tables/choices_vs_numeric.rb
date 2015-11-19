require 'spout/models/tables/default'
require 'spout/helpers/array_statistics'

module Spout
  module Models
    module Tables
      # Generates a table that displays choices versus numeric values
      class ChoicesVsNumeric < Spout::Models::Tables::Default
        def title
          "#{@variable.display_name} vs #{@chart_variable.display_name}"
        end

        def headers
          categories = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            bucket = @filtered_subjects.send(quartile).collect(&@chart_variable.id.to_sym)
            "#{bucket.min} to #{bucket.max} #{@chart_variable.units}"
          end

          [[''] + categories + ['Total']]
        end

        def footers
          total_values = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            { text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.send(quartile).count, :count), style: 'font-weight:bold' }
          end

          [
            [{ text: 'Total', style: 'font-weight:bold' }] + total_values + [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count, :count), style: 'font-weight:bold' }]
          ]
        end

        def rows
          rows_result = filtered_domain_options(@variable).collect do |option|
            row_subjects = @filtered_subjects.select { |s| s.send(@variable.id) == option.value }

            data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
              count = @filtered_subjects.send(quartile).count { |s| s.send(@variable.id) == option.value }
              Spout::Helpers::TableFormatting.format_number(count, :count)
            end

            [option.display_name] + data + [{ text: Spout::Helpers::TableFormatting.format_number(row_subjects.count, :count), style: 'font-weight:bold' }]
          end

          if @filtered_subjects.count { |s| s.send(@variable.id).is_a?(Spout::Models::Empty) } > 0
            unknown_values = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
              count = @filtered_subjects.send(quartile).count { |s| s.send(@variable.id).is_a?(Spout::Models::Empty) }
              { text: Spout::Helpers::TableFormatting.format_number(count, :count), class: 'text-muted' }
            end
            rows_result << [{ text: 'Unknown', class: 'text-muted'}] + unknown_values + [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count { |s| s.send(@variable.id).is_a?(Spout::Models::Empty) }, :count), style: 'font-weight:bold', class: 'text-muted' }]
          end
          rows_result
        end
      end
    end
  end
end
