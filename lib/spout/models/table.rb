require 'spout/models/variable'
# require 'spout/models/bucket'
require 'spout/helpers/array_statistics'
require 'spout/helpers/table_formatting'

module Spout
  module Models
    class Table

      attr_accessor :chart_variable, :subjects, :variable, :subtitle

      def initialize(chart_type, subjects, variable, subtitle)
        @chart_variable = Spout::Models::Variable.find_by_id(chart_type)
        @subjects = subjects
        @filtered_subjects = @subjects.select{ |s| s.send(@chart_variable.id) != nil } rescue @filtered_subjects = []

        @variable = variable
        @values = @filtered_subjects.collect(&@variable.id.to_sym).uniq rescue @values = [] # Depends on which table needs filtered subjects
        # @values = @subjects.collect(&@variable.id.to_sym).uniq rescue @values = [] # Depends on which table needs filtered subjects
        @values_unique = @values.uniq
        # @buckets = continuous_buckets


        @subtitle = subtitle
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
        "#{@variable.display_name} by #{@chart_variable.display_name}"
      end

      def headers
        headers_result = []
        if numeric_versus_choices?
          # table_arbitrary
          headers_result = [
            [""] + Spout::Helpers::ArrayStatistics::calculations.collect{|calculation_label, calculation_method| calculation_label} + ["Total"]
          ]
        elsif choices_versus_choices?
          # table_arbitrary_choices
          headers_result = [
            [""] + filtered_domain_options(@chart_variable).collect{|option| option.display_name} + ["Total"]
          ]
        elsif numeric_versus_numeric?

        elsif choices_versus_numeric?

        else

        end
        headers_result
      end

      def footers
        footers_result = []
        if numeric_versus_choices?
          # table_arbitrary
          total_values = Spout::Helpers::ArrayStatistics::calculations.collect do |calculation_label, calculation_method, calculation_type, calculation_format|
            total_count = @filtered_subjects.collect(&@variable.id.to_sym).send(calculation_method)
            { text: Spout::Helpers::TableFormatting::format_number(total_count, calculation_type, calculation_format), style: "font-weight:bold" }
          end

          footers_result = [
            [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: Spout::Helpers::TableFormatting::format_number(@filtered_subjects.count, :count), style: 'font-weight:bold'}]
          ]
        elsif choices_versus_choices?
          # table_arbitrary_choices
          total_values = filtered_domain_options(@chart_variable).collect do |option|
            total_count = @filtered_subjects.select{|s| s.send(@chart_variable.id) == option.value }.count
            { text: (total_count == 0 ? "-" : Spout::Helpers::TableFormatting::format_number(total_count, :count)), style: "font-weight:bold" }
          end

          footers_result = [
            [{ text: "Total", style: "font-weight:bold" }] + total_values + [{ text: Spout::Helpers::TableFormatting::format_number(@filtered_subjects.count, :count), style: 'font-weight:bold'}]
          ]

        elsif numeric_versus_numeric?

        elsif choices_versus_numeric?

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
          # table_arbitrary_choices

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

        elsif choices_versus_numeric?

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

      # def continuous_buckets
      #   values_numeric = @values.select{|v| v.kind_of? Numeric}
      #   return [] if values_numeric.count == 0
      #   minimum_bucket = values_numeric.min
      #   maximum_bucket = values_numeric.max
      #   max_buckets = 12
      #   bucket_size = ((maximum_bucket - minimum_bucket) / max_buckets.to_f)
      #   precision = (bucket_size == 0 ? 0 : [-Math.log10(bucket_size).floor, 0].max)

      #   buckets = []
      #   (0..(max_buckets-1)).to_a.each do |index|
      #     start = (minimum_bucket + index * bucket_size)
      #     stop = (start + bucket_size)
      #     buckets << Spout::Models::Bucket.new(start.round(precision),stop.round(precision))
      #   end
      #   buckets
      # end

      # def get_bucket(value)
      #   return nil if @buckets.size == 0 or not value.kind_of?(Numeric)
      #   @buckets.each do |b|
      #     return b.display_name if b.in_bucket?(value)
      #   end
      #   if value <= @buckets.first.start
      #     @buckets.first.display_name
      #   else
      #     @buckets.last.display_name
      #   end
      # end

      # Returns variable options that are either:
      # a) are not missing codes
      # b) or are marked as missing codes but represented in the dataset
      def filtered_domain_options(variable)
        variable.domain.options.select do |o|
          o.missing != true or (o.missing == true and @values_unique.include?(o.value))
        end
      end

    end
  end
end
