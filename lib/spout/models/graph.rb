
# require 'spout/models/dictionary' # Includes forms, variables, and domains
require 'spout/models/variable'

module Spout
  module Models
    class Graph

      attr_accessor :chart_variable, :subjects, :variable, :visits

      def initialize(chart_type, subjects, variable, visits)
        @chart_variable = Spout::Models::Variable.find_by_id(chart_type)
        @subjects = subjects
        @variable = variable # Spout::Models::Variable
        # @method = @variable.id
        @visits = visits # This should be Spout::Models::Domain
        @values = subjects.collect(&@variable.id.to_sym).uniq
        @values_unique = @values.uniq

        @buckets = continuous_buckets
      end

      # Public methods

      def has_graph?
        # @variable.type == 'choices' and @variable.domain.present?
        # Other
      end

      def to_hash
      end

      def title
        if @visits == nil
          @variable.display_name
        else
          "#{@variable.display_name} by #{@chart_variable.display_name}"
        end
      end

      def subtitle
        "By Visit"
      end

      def categories
        @categories ||= begin
          categories_result = []
          if histogram?
            if @variable.type == 'choices'
              categories_result = @variable.domain.options.select{|o| o.missing != true or (o.missing == true and @values_unique.include?(o.value))}.collect(&:display_name)
            else
              categories_result = @buckets.collect{|b| "#{b[0]} to #{b[1]}"}
            end
          else
            # chart_arbitrary_choices_by_quartile
            # categories_result = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
            #   bucket = filtered_subjects.send(quartile).collect(&chart_type.to_sym)
            #   "#{bucket.min} to #{bucket.max}"
            # end

            # chart_arbitrary_by_quartile
            # categories = ["Quartile One", "Quartile Two", "Quartile Three", "Quartile Four"]

            # chart_arbitrary_choices
            # categories = chart_variable_domain.collect{|a| a[0]}

            # chart_arbitrary
            # categories = []
            # visits.each do |visit_display_name, visit_value|
            #   visit_subjects = subjects.select{ |s| s._visit == visit_value and s.send(method) != nil }
            #   if visit_subjects.count > 0
            #     categories << visit_display_name
            #   end
            # end
          end

          categories_result
        end
      end

      def units
        units_result = ''
        if histogram?
          units_result = 'Subjects'
        else

          # chart_arbitrary_choices_by_quartile
          # units_result = 'percent'

          # chart_arbitrary_by_quartile
          # units_result = json["units"]

          # chart_arbitrary_choices
          # units_result = 'percent'

          # chart_arbitrary
          # units = json["units"]

        end

        units_result
      end

      def series
        series_result = []
        if histogram?
          # chart_histogram
          @chart_variable.domain.options.each do |option|
            visit_subjects = @subjects.select{ |s| s.send(@chart_variable.id) == option.value and s.send(@variable.id) != nil }.collect(&@variable.id.to_sym).sort
            next unless visit_subjects.size > 0

            data = []

            if @variable.type == 'choices'
              data = @variable.domain.options.collect do |option|
                visit_subjects.select{ |v| v == option.value }.count
              end
            else
              visit_subjects.group_by{|v| get_bucket(v) }.each do |key, values|
                data[categories.index(key)] = values.count if categories.index(key)
              end
            end

            series_result << { name: option.display_name, data: data }

          end
          # chart_variable_domain.each do |display_name, value|
          #   visit_subjects = subjects.select{ |s| s.send(chart_type) == value and s.send(method) != nil }.collect(&method.to_sym).sort
          #   next unless visit_subjects.size > 0

          #   data = pull_data(json, visit_subjects, buckets, categories, domain_json)

          #   series << { name: display_name, data: data }
          # end
        else

          # chart_arbitrary_choices_by_quartile
          # domain_json.each do |option_hash|
          #   data = [:quartile_one, :quartile_two, :quartile_three, :quartile_four].collect do |quartile|
          #     filtered_subjects.send(quartile).select{ |s| s.send(method) == option_hash['value'] }.count
          #   end

          #   series << { name: option_hash['display_name'], data: data } unless filtered_subjects.size == 0
          # end

          # chart_arbitrary_by_quartile
          # visits.each do |visit_display_name, visit_value|
          #   data = []
          #   filtered_subjects = subjects.select{ |s| s._visit == visit_value and s.send(method) != nil and s.send(chart_type) != nil }.sort_by(&chart_type.to_sym)

          #   [:quartile_one, :quartile_two, :quartile_three, :quartile_four].each do |quartile|
          #     array = filtered_subjects.send(quartile).collect(&method.to_sym)
          #     data << {       y: (array.mean.round(1) rescue 0.0),
          #                  stddev: ("%0.1f" % array.standard_deviation rescue ''),
          #                  median: ("%0.1f" % array.median rescue ''),
          #                     min: ("%0.1f" % array.min rescue ''),
          #                     max: ("%0.1f" % array.max rescue ''),
          #                       n: array.n }
          #   end

          #   series << { name: visit_display_name, data: data } unless filtered_subjects.size == 0
          # end

          # chart_arbitrary_choices
          # domain_json.each do |option_hash|
          #   domain_values = subjects.select{ |s| s.send(method) == option_hash['value'] }

          #   data = chart_variable_domain.collect do |display_name, value|
          #     domain_values.select{ |s| s.send(chart_type) == value }.count
          #   end
          #   series << { name: option_hash['display_name'], data: data }
          # end

          # chart_arbitrary
          # chart_variable_domain.each_with_index do |(display_name, value), index|
          #   series << { name: display_name, data: data[index] }
          # end
        end
        series_result
      end

      def stacking
        stacking_result = nil

        if histogram?
          # chart_histogram
        else

          # chart_arbitrary_choices_by_quartile
          # stacking_result = 'percent'

          # chart_arbitrary_by_quartile

          # chart_arbitrary_choices
          # stacking_result = 'percent'

          # chart_arbitrary
        end

        stacking_result
      end

      def x_axis_title
        x_axis_title_result = nil
        if histogram?
          x_axis_title_result = @variable.units
        else
          # chart_arbitrary_choices_by_quartile

          # chart_arbitrary_by_quartile

          # chart_arbitrary_choices

          # chart_arbitrary
        end

        x_axis_title_result
      end

      private

      def histogram?
        @visits == nil
      end

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
          buckets << [start.round(precision),stop.round(precision)]
        end
        buckets
      end

      def get_bucket(value)
        return nil if @buckets.size == 0 or not value.kind_of?(Numeric)
        @buckets.each do |b|
          return "#{b[0]} to #{b[1]}" if value >= b[0] and value <= b[1]
        end
        if value <= @buckets.first[0]
          "#{@buckets.first[0]} to #{@buckets.first[1]}"
        else
          "#{@buckets.last[0]} to #{@buckets.last[1]}"
        end
      end

    end
  end
end
