# frozen_string_literal: true

require "spout/models/graphables/default"

module Spout
  module Models
    module Graphables
      class NumericVsChoices < Spout::Models::Graphables::Default
        def categories
          categories_result = []
          @stratification_variable.domain.options.each do |option|
            visit_subjects = @subjects.select{ |s| s._visit == option.value and s.send(@variable.id) != nil } rescue visit_subjects = []
            if visit_subjects.count > 0
              categories_result << option.display_name
            end
          end
          categories_result
        end

        def units
          @variable.units
        end

        def series
          data = []

          @stratification_variable.domain.options.each do |option|
            visit_subjects = @subjects.select{ |s| s._visit == option.value and s.send(@variable.id) != nil } rescue visit_subjects = []
            if visit_subjects.count > 0
              filtered_domain_options(@chart_variable).each_with_index do |filtered_option, index|
                values = visit_subjects.select{|s| s.send(@chart_variable.id) == filtered_option.value }.collect(&@variable.id.to_sym)
                data[index] ||= []
                data[index] << (values.mean.round(2) rescue 0.0)
              end
            end
          end

          filtered_domain_options(@chart_variable).each_with_index.collect do |option, index|
            { name: option.display_name, data: data[index] }
          end
        end
      end
    end
  end
end
