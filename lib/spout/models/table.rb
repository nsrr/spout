require 'spout/models/variable'
# require 'spout/models/bucket'
require 'spout/helpers/array_statistics'
require 'spout/helpers/table_formatting'

module Spout
  module Models
    class Table

      attr_accessor :chart_variable, :subjects, :variable, :subtitle

      def initialize(chart_type, subjects, variable, subtitle)
        @variable = variable
        @subtitle = subtitle
        @subjects = subjects

        @chart_variable = Spout::Models::Variable.find_by_id(chart_type)
        @filtered_subjects = @subjects.select{ |s| s.send(@chart_variable.id) != nil } rescue @filtered_subjects = []
        @filtered_both_variables_subjects = subjects.select{ |s| s.send(@variable.id) != nil and s.send(@chart_variable.id) != nil }.sort_by(&@chart_variable.id.to_sym) rescue @filtered_both_variables_subjects = []

        @values = @filtered_subjects.collect(&@variable.id.to_sym).uniq rescue @values = []

        @values_unique = @values.uniq

        @values_both_variables = @filtered_both_variables_subjects.collect(&@variable.id.to_sym).uniq rescue @values_both_variables = []
        @values_both_variables_unique = @values_both_variables.uniq
      end

      # Public methods

      def to_hash
        if @values == [] or @variable == nil or @chart_variable == nil
          nil
        elsif @variable.type == 'choices' and @variable.domain.options == []
          nil
        elsif @chart_variable == nil
          nil
        elsif @chart_variable and @chart_variable.type == 'choices' and @chart_variable.domain.options == []
          nil
        else
          { title: title, subtitle: @subtitle, headers: headers, footers: footers, rows: rows }
        end
      end

      def title
        if numeric_versus_choices?
          "#{@chart_variable.display_name} vs #{@variable.display_name}"
        elsif choices_versus_choices?
          "#{@variable.display_name} vs #{@chart_variable.display_name}"
        elsif numeric_versus_numeric?
          "#{@chart_variable.display_name} vs #{@variable.display_name}"
        elsif choices_versus_numeric?
          "#{@variable.display_name} vs #{@chart_variable.display_name}"
        else

        end
      end

      def headers
        headers_result = []
        if numeric_versus_choices?
          headers_result = [
            [""] + Spout::Helpers::ArrayStatistics::calculations.collect{|calculation_label, calculation_method| calculation_label} + ["Total"]
          ]
        elsif choices_versus_choices?
          headers_result = [
            [""] + filtered_domain_options(@chart_variable).collect{|option| option.display_name} + ["Total"]
          ]
        elsif numeric_versus_numeric?
          headers_result = [
            [""] + Spout::Helpers::ArrayStatistics::calculations.collect{|calculation_label, calculation_method| calculation_label} + ["Total"]
          ]
        elsif choices_versus_numeric?
          # table_arbitrary_choices_by_quartile
          categories = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            bucket = @filtered_both_variables_subjects.send(quartile).collect(&@chart_variable.id.to_sym)
            "#{bucket.min} to #{bucket.max} #{@chart_variable.units}"
          end

          headers_result = [
            [""] + categories + ["Total"]
          ]
        else

        end
        headers_result
      end

      def footers
        footers_result = []
        if numeric_versus_choices?
          total_values = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
            total_count = @filtered_subjects.collect(&@variable.id.to_sym).send(calculation_method)
            { text: Spout::Helpers::TableFormatting::format_number(total_count, calculation_type, calculation_format), style: "font-weight:bold" }
          end
          footers_result = [
            [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: Spout::Helpers::TableFormatting::format_number(@filtered_subjects.count, :count), style: 'font-weight:bold'}]
          ]
        elsif choices_versus_choices?
          total_values = filtered_domain_options(@chart_variable).collect do |option|
            total_count = @filtered_subjects.select{|s| s.send(@chart_variable.id) == option.value }.count
            { text: (total_count == 0 ? "-" : Spout::Helpers::TableFormatting::format_number(total_count, :count)), style: "font-weight:bold" }
          end
          footers_result = [
            [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: Spout::Helpers::TableFormatting::format_number(@filtered_subjects.count, :count), style: 'font-weight:bold'}]
          ]
        elsif numeric_versus_numeric?
          total_values = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
            total_count = @filtered_both_variables_subjects.collect(&@variable.id.to_sym).send(calculation_method)
            { text: Spout::Helpers::TableFormatting::format_number(total_count, calculation_type, calculation_format), style: "font-weight:bold" }
          end

          footers_result = [
            [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: Spout::Helpers::TableFormatting::format_number(@filtered_both_variables_subjects.count, :count), style: 'font-weight:bold'}]
          ]
        elsif choices_versus_numeric?
          total_values = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            { text: Spout::Helpers::TableFormatting::format_number(@filtered_both_variables_subjects.send(quartile).count, :count), style: "font-weight:bold" }
          end

          footers_result = [
            [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: Spout::Helpers::TableFormatting::format_number(@filtered_both_variables_subjects.count, :count), style: 'font-weight:bold'}]
          ]
        else

        end
        footers_result
      end

      def rows
        rows_result = []
        if numeric_versus_choices?
          # table_arbitrary
          rows_result = filtered_domain_options(@chart_variable).collect do |option|
            row_subjects = @filtered_subjects.select{ |s| s.send(@chart_variable.id) == option.value }

            row_cells = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
              count = row_subjects.collect(&@variable.id.to_sym).send(calculation_method)
              (count == 0 && calculation_method == :count) ? { text: '-', class: 'text-muted' } : Spout::Helpers::TableFormatting::format_number(count, calculation_type, calculation_format)
            end

            [option.display_name] + row_cells + [{ text: Spout::Helpers::TableFormatting::format_number(row_subjects.count, :count), style: 'font-weight:bold'}]
          end
        elsif choices_versus_choices?
          rows_result = filtered_domain_options(@variable).collect do |option|
            row_subjects = @filtered_subjects.select{ |s| s.send(@variable.id) == option.value }
            row_cells = filtered_domain_options(@chart_variable).collect do |chart_option|
              count = row_subjects.select{ |s| s.send(@chart_variable.id) == chart_option.value }.count
              count > 0 ? Spout::Helpers::TableFormatting::format_number(count, :count) : { text: '-', class: 'text-muted' }
            end

            total = row_subjects.count

            [option.display_name] + row_cells + [total == 0 ? { text: '-', class: 'text-muted' } : { text: Spout::Helpers::TableFormatting::format_number(total, :count), style: 'font-weight:bold'}]
          end

          if @filtered_subjects.select{|s| s.send(@variable.id) == nil }.count > 0
            unknown_values = filtered_domain_options(@chart_variable).collect do |chart_option|
              { text: Spout::Helpers::TableFormatting::format_number(@filtered_subjects.select{ |s| s.send(@chart_variable.id) == chart_option.value and s.send(@variable.id) == nil }.count, :count), class: 'text-muted' }
            end
            rows_result << [{ text: 'Unknown', class: 'text-muted'}] + unknown_values + [ { text: Spout::Helpers::TableFormatting::format_number(@filtered_subjects.select{|s| s.send(@variable.id) == nil}.count, :count), style: 'font-weight:bold', class: 'text-muted' } ]
          end
        elsif numeric_versus_numeric?
          rows_result = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            bucket = @filtered_both_variables_subjects.send(quartile)
            row_subjects = bucket.collect(&@variable.id.to_sym)
            data = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
              Spout::Helpers::TableFormatting::format_number(row_subjects.send(calculation_method), calculation_type, calculation_format)
            end

            row_name = if row_subjects.size == 0
              quartile.to_s.capitalize.gsub('_one', ' One').gsub('_two', ' Two').gsub('_three', ' Three').gsub('_four', ' Four')
            else
              "#{bucket.collect(&@chart_variable.id.to_sym).min} to #{bucket.collect(&@chart_variable.id.to_sym).max} #{@chart_variable.units}"
            end

            [row_name] + data + [{ text: Spout::Helpers::TableFormatting::format_number(row_subjects.count, :count), style: 'font-weight:bold'}]
          end
        elsif choices_versus_numeric?
          rows_result = filtered_both_variables_domain_options(@variable).collect do |option|
            row_subjects = @filtered_both_variables_subjects.select{ |s| s.send(@variable.id) == option.value }

            data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
              bucket = @filtered_both_variables_subjects.send(quartile).select{ |s| s.send(@variable.id) == option.value }
              Spout::Helpers::TableFormatting::format_number(bucket.count, :count)
            end

            [option.display_name] + data + [{ text: Spout::Helpers::TableFormatting::format_number(row_subjects.count, :count), style: 'font-weight:bold'}]
          end
        else

        end
        rows_result
      end

      private

      def numeric_versus_choices?
        ['numeric', 'integer'].include?(@variable.type) and @chart_variable.type == 'choices'
      end

      def choices_versus_choices?
        @variable.type == 'choices' and @chart_variable.type == 'choices'
      end

      def numeric_versus_numeric?
        ['numeric', 'integer'].include?(@variable.type) and ['numeric', 'integer'].include?(@chart_variable.type)
      end

      def choices_versus_numeric?
        @variable.type == 'choices' and ['numeric', 'integer'].include?(@chart_variable.type)
      end

      # Returns variable options that are either:
      # a) are not missing codes
      # b) or are marked as missing codes but represented in the dataset
      def filtered_domain_options(variable)
        variable.domain.options.select do |o|
          o.missing != true or (o.missing == true and @values_unique.include?(o.value))
        end
      end

      def filtered_both_variables_domain_options(variable)
        variable.domain.options.select do |o|
          o.missing != true or (o.missing == true and @values_both_variables_unique.include?(o.value))
        end
      end

    end
  end
end
