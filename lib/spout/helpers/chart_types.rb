require 'spout/helpers/array_statistics'
require 'spout/helpers/table_formatting'

module Spout
  module Helpers
    class ChartTypes
      def self.get_bucket(buckets, value)
        return nil if buckets.size == 0 or not value.kind_of?(Numeric)
        buckets.each do |b|
          return "#{b[0]} to #{b[1]}" if value >= b[0] and value <= b[1]
        end
        if value <= buckets.first[0]
          "#{buckets.first[0]} to #{buckets.first[1]}"
        else
          "#{buckets.last[0]} to #{buckets.last[1]}"
        end
      end

      def self.continuous_buckets(values)
        values.select!{|v| v.kind_of? Numeric}
        return [] if values.count == 0
        minimum_bucket = values.min
        maximum_bucket = values.max
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
    end
  end
end
