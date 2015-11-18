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
            bucket = @filtered_both_variables_subjects.send(quartile).collect(&@chart_variable.id.to_sym)
            "#{bucket.min} to #{bucket.max} #{@chart_variable.units}"
          end

          [[''] + categories + ['Total']]
        end

        def footers
          total_values = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            { text: Spout::Helpers::TableFormatting.format_number(@filtered_both_variables_subjects.send(quartile).count, :count), style: 'font-weight:bold' }
          end

          [
            [{ text: 'Total', style: 'font-weight:bold' }] + total_values + [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_both_variables_subjects.count, :count), style: 'font-weight:bold' }]
          ]
        end

        def rows
          filtered_both_variables_domain_options(@variable).collect do |option|
            row_subjects = @filtered_both_variables_subjects.select { |s| s.send(@variable.id) == option.value }

            data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
              bucket = @filtered_both_variables_subjects.send(quartile).select { |s| s.send(@variable.id) == option.value }
              Spout::Helpers::TableFormatting.format_number(bucket.count, :count)
            end

            [option.display_name] + data + [{ text: Spout::Helpers::TableFormatting.format_number(row_subjects.count, :count), style: 'font-weight:bold' }]
          end
        end
      end
    end
  end
end
