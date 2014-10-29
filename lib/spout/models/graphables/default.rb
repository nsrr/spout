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

          @values = subjects.collect(&@variable.id.to_sym) rescue @values = []
          @values_unique = @values.uniq

          @buckets = continuous_buckets
        end

        def to_hash
          if @variable == nil or @chart_variable == nil or @values == []
            nil
          elsif @variable.type == 'choices' and @variable.domain.options == []
            nil
          elsif @chart_variable.type == 'choices' and @chart_variable.domain.options == []
            nil
          else
            { title: title, subtitle: subtitle, categories: categories, units: units, series: series, stacking: stacking, x_axis_title: x_axis_title }
          end
        end

        def title
          "#{@variable.display_name} by #{@chart_variable.display_name}"
        end

        def subtitle
          "By Visit"
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
          values_numeric = @values.select{|v| v.kind_of? Numeric}
          return [] if values_numeric.count == 0
          minimum_bucket = values_numeric.min
          maximum_bucket = values_numeric.max
          max_buckets = 12
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

        def get_bucket(value)
          return nil if @buckets.size == 0 or not value.kind_of?(Numeric)
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
            o.missing != true or (o.missing == true and @values_unique.include?(o.value))
          end
        end

      end
    end
  end
end
