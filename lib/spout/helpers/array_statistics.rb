# Extensions to the Array class to calculate quartiles, outliers, and statistics
class Array
  def compact_empty
    compact.reject { |a| a.is_a?(Spout::Models::Empty) }
  end

  def n
    compact_empty.count
  end

  def mean
    array = compact_empty
    return nil if array.size == 0
    array.inject(:+).to_f / array.size
  end

  def sample_variance
    array = compact_empty
    m = array.mean
    sum = array.inject(0) { |a, e| a + (e - m)**2 }
    sum / (array.length - 1).to_f
  end

  def standard_deviation
    array = compact_empty
    return nil if array.size < 2
    Math.sqrt(array.sample_variance)
  end

  def median
    array = compact_empty.sort
    return nil if array.size == 0
    len = array.size
    len.odd? ? array[len / 2] : (array[len / 2 - 1] + array[len / 2]).to_f / 2
  end

  def unknown
    count { |a| a.is_a?(Spout::Models::Empty) }
  end

  def quartile_sizes
    quartile_size = count / 4
    quartile_fraction = count % 4

    quartile_sizes = [quartile_size] * 4
    (0..quartile_fraction - 1).to_a.each do |index|
      quartile_sizes[index] += 1
    end

    quartile_sizes
  end

  def quartile_one
    self[0..(quartile_sizes[0] - 1)]
  end

  def quartile_two
    sizes = quartile_sizes
    start = sizes[0]
    stop = start + sizes[1] - 1
    self[start..stop]
  end

  def quartile_three
    sizes = quartile_sizes
    start = sizes[0] + sizes[1]
    stop = start + sizes[2] - 1
    self[start..stop]
  end

  def quartile_four
    sizes = quartile_sizes
    start = sizes[0] + sizes[1] + sizes[2]
    stop = start + sizes[3] - 1
    self[start..stop]
  end

  def compact_min
    compact_empty.min
  end

  def compact_max
    compact_empty.max
  end

  def outliers
    array = compact_empty.sort.select { |v| v.is_a?(Numeric) }
    q1 = (array.quartile_one + array.quartile_two).median
    q3 = (array.quartile_three + array.quartile_four).median
    return [] if q1.nil? || q3.nil?
    iq_range = q3 - q1
    inner_fence_lower = q1 - iq_range * 1.5
    inner_fence_upper = q3 + iq_range * 1.5
    array.select { |v| v > inner_fence_upper || v < inner_fence_lower }
  end

  def major_outliers
    array = compact_empty.sort.select { |v| v.is_a?(Numeric) }
    q1 = (array.quartile_one + array.quartile_two).median
    q3 = (array.quartile_three + array.quartile_four).median
    return [] if q1.nil? || q3.nil?
    iq_range = q3 - q1
    outer_fence_lower = q1 - iq_range * 3
    outer_fence_upper = q3 + iq_range * 3
    array.select { |v| v > outer_fence_upper || v < outer_fence_lower }
  end

  def minor_outliers
    outliers - major_outliers
  end
end

module Spout
  module Helpers
    class ArrayStatistics
      def self.calculations
        [['N', :n, :count],
         ['Mean', :mean, :decimal],
         ['StdDev', :standard_deviation, :decimal, '± %s'],
         ['Median', :median, :decimal],
         ['Min', :compact_min, :decimal],
         ['Max', :compact_max, :decimal],
         ['Unknown', :unknown, :count]]
      end
    end
  end
end
