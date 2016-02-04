# frozen_string_literal: true

require 'spout/models/variable'
require 'spout/models/bucket'

module Spout
  module Models
    module Graphables
      class Default
        attr_reader :variable, :chart_variable, :stratification_variable, :subjects

        def initialize(variable, chart_variable, stratification_variable, subjects)
          @variable = variable
          @chart_variable = chart_variable
          @stratification_variable = stratification_variable
          @subjects = subjects
          begin
            @values_unique = subjects.collect(&@variable.id.to_sym).reject { |a| a.is_a?(Spout::Models::Empty) }.uniq
          rescue
            @values_unique = []
          end
          @buckets = continuous_buckets
        end

        def to_hash
          { title: title, subtitle: subtitle, categories: categories, units: units, series: series, stacking: stacking, x_axis_title: x_axis_title } if valid?
        end

        def valid?
          if @variable.nil? || @chart_variable.nil? || @values_unique == []
            false
          elsif @variable.type == 'choices' && @variable.domain.options == []
            false
          elsif @chart_variable.type == 'choices' && @chart_variable.domain.options == []
            false
          else
            true
          end
        end

        def title
          "#{@variable.display_name} by #{@chart_variable.display_name}"
        end

        def subtitle
          'By Visit'
        end

        def categories
          []
        end

        def units
          nil
        end

        def series
          []
        end

        def stacking
          nil
        end

        def x_axis_title
          nil
        end

        private

        def continuous_buckets
          values_numeric = @values_unique.select { |v| v.is_a? Numeric }

          return [] if values_numeric.count == 0
          minimum_bucket = values_numeric.min
          maximum_bucket = values_numeric.max
          max_buckets = 12
          if all_integer?(values_numeric) && (maximum_bucket - minimum_bucket < max_buckets)
            max_buckets = maximum_bucket - minimum_bucket
            return discrete_buckets
          end

          bucket_size = ((maximum_bucket - minimum_bucket) / max_buckets.to_f)
          precision = (bucket_size == 0 ? 0 : [-Math.log10(bucket_size).floor, 0].max)

          buckets = []
          (0..(max_buckets-1)).to_a.each do |index|
            start = (minimum_bucket + index * bucket_size)
            stop = (start + bucket_size)
            buckets << Spout::Models::Bucket.new(start.round(precision),stop.round(precision))
          end
          buckets
        end

        def discrete_buckets
          values_numeric = @values_unique.select { |v| v.is_a? Numeric }
          minimum_bucket = values_numeric.min
          maximum_bucket = values_numeric.max
          max_buckets = maximum_bucket - minimum_bucket + 1
          bucket_size = 1
          precision = 0

          buckets = []
          (0..(max_buckets-1)).to_a.each do |index|
            start = (minimum_bucket + index * bucket_size)
            stop = start
            buckets << Spout::Models::Bucket.new(start.round(precision), stop.round(precision), discrete: true)
          end
          buckets
        end

        def all_integer?(values_numeric)
          count = values_numeric.count { |v| Integer(format('%.0f', v)) == v }
          count == values_numeric.size
        end

        def get_bucket(value)
          return nil if @buckets.size == 0 || !value.is_a?(Numeric)
          @buckets.each do |b|
            return b.display_name if b.in_bucket?(value)
          end
          if value <= @buckets.first.start
            @buckets.first.display_name
          else
            @buckets.last.display_name
          end
        end

        # Returns variable options that are either:
        # a) are not missing codes
        # b) or are marked as missing codes but represented in the dataset
        def filtered_domain_options(variable)
          variable.domain.options.select do |o|
            o.missing != true || (o.missing == true && @values_unique.include?(o.value))
          end
        end
      end
    end
  end
end
