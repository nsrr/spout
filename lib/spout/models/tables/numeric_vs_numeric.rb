# frozen_string_literal: true

require 'spout/models/tables/default'
require 'spout/helpers/array_statistics'

module Spout
  module Models
    module Tables
      class NumericVsNumeric < Spout::Models::Tables::Default
        def title
          "#{@chart_variable.display_name} vs #{@variable.display_name}"
        end

        def headers
          [[''] + Spout::Helpers::ArrayStatistics.calculations.collect(&:first) + ['Total']]
        end

        def footers
          total_values = Spout::Helpers::ArrayStatistics.calculations.collect do |_calculation_label, calculation_method, calculation_type, calculation_format|
            total_count = @filtered_subjects.collect(&@variable.id.to_sym).send(calculation_method)
            { text: Spout::Helpers::TableFormatting.format_number(total_count, calculation_type, calculation_format), style: 'font-weight:bold' }
          end

          [
            [{ text: 'Total', style: 'font-weight:bold' }] + total_values + [{ text: Spout::Helpers::TableFormatting.format_number(@filtered_subjects.count, :count), style: 'font-weight:bold' }]
          ]
        end

        def rows
          [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            bucket = @filtered_subjects.send(quartile)
            row_subjects = bucket.collect(&@variable.id.to_sym)
            data = Spout::Helpers::ArrayStatistics.calculations.collect do |_calculation_label, calculation_method, calculation_type, calculation_format|
              Spout::Helpers::TableFormatting.format_number(row_subjects.send(calculation_method), calculation_type, calculation_format)
            end

            row_name = get_row_name(quartile, bucket, row_subjects)

            [row_name] + data + [{ text: Spout::Helpers::TableFormatting.format_number(row_subjects.count, :count), style: 'font-weight:bold' }]
          end
        end

        private

        def get_row_name(quartile, bucket, row_subjects)
          if row_subjects.size == 0
            quartile.to_s.capitalize.gsub('_one', ' One').gsub('_two', ' Two').gsub('_three', ' Three').gsub('_four', ' Four')
          else
            "#{bucket.collect(&@chart_variable.id.to_sym).min} to #{bucket.collect(&@chart_variable.id.to_sym).max} #{@chart_variable.units}"
          end
        end
      end
    end
  end
end
