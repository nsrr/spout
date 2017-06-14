require "test_helper"
require "spout/helpers/chart_types"

module HelperTests
  class ChartTypesTest < Minitest::Test
    def test_precision_for_infinity
      assert_equal [[0, 0]]*12, Spout::Helpers::ChartTypes::continuous_buckets([0,0])
    end

    def test_buckets_with_zero_precision
      assert_equal [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [7, 8], [8, 9], [9, 10], [10, 11], [11, 12], [12, 13]], Spout::Helpers::ChartTypes::continuous_buckets([0.0,13.0])
    end

    def test_buckets_with_one_precision
      assert_equal [[0.1, 0.2], [0.2, 0.3], [0.3, 0.4], [0.4, 0.5], [0.5, 0.6], [0.6, 0.7], [0.7, 0.8], [0.8, 0.9], [0.9, 1.0], [1.0, 1.1], [1.1, 1.2], [1.2, 1.3]], Spout::Helpers::ChartTypes::continuous_buckets([0.1,1.3])
    end

    def test_buckets_with_two_precision
      assert_equal [[0.01, 0.02], [0.02, 0.03], [0.03, 0.04], [0.04, 0.05], [0.05, 0.06], [0.06, 0.07], [0.07, 0.08], [0.08, 0.09], [0.09, 0.1], [0.1, 0.11], [0.11, 0.12], [0.12, 0.13]], Spout::Helpers::ChartTypes::continuous_buckets([0.01,0.13])
    end

    def test_get_bucket_with_empty_buckets
      assert_nil Spout::Helpers::ChartTypes::get_bucket([], 1)
    end

    def test_get_bucket_labels
      buckets = [[0.1, 0.2], [0.2, 0.3], [0.3, 0.4], [0.4, 0.5], [0.5, 0.6], [0.6, 0.7], [0.7, 0.8], [0.8, 0.9], [0.9, 1.0], [1.0, 1.1], [1.1, 1.2], [1.2, 1.3]]
      assert_equal "0.1 to 0.2", Spout::Helpers::ChartTypes::get_bucket(buckets, 0.1)
      assert_equal "0.1 to 0.2", Spout::Helpers::ChartTypes::get_bucket(buckets, 0.2)
      assert_equal "0.2 to 0.3", Spout::Helpers::ChartTypes::get_bucket(buckets, 0.21)
      assert_equal "0.2 to 0.3", Spout::Helpers::ChartTypes::get_bucket(buckets, 0.3)
    end

    # Underflow gets placed into the first bucket
    # The first and the last bucket may be relabeled to specify this
    def test_get_bucket_underflow
      buckets = [[0.1, 0.2], [0.2, 0.3], [0.3, 0.4], [0.4, 0.5], [0.5, 0.6], [0.6, 0.7], [0.7, 0.8], [0.8, 0.9], [0.9, 1.0], [1.0, 1.1], [1.1, 1.2], [1.2, 1.3]]
      assert_equal "0.1 to 0.2", Spout::Helpers::ChartTypes::get_bucket(buckets, 0.0)
    end

    # Overflow gets placed into the last bucket
    # The first and the last bucket may be relabeled to specify this
    def test_get_bucket_overflow
      buckets = [[0.1, 0.2], [0.2, 0.3], [0.3, 0.4], [0.4, 0.5], [0.5, 0.6], [0.6, 0.7], [0.7, 0.8], [0.8, 0.9], [0.9, 1.0], [1.0, 1.1], [1.1, 1.2], [1.2, 1.3]]
      assert_equal "1.2 to 1.3", Spout::Helpers::ChartTypes::get_bucket(buckets, 1.4)
    end

    def test_get_bucket_for_nil_or_non_number_value
      buckets = [[0.1, 0.2], [0.2, 0.3], [0.3, 0.4], [0.4, 0.5], [0.5, 0.6], [0.6, 0.7], [0.7, 0.8], [0.8, 0.9], [0.9, 1.0], [1.0, 1.1], [1.1, 1.2], [1.2, 1.3]]
      assert_nil Spout::Helpers::ChartTypes::get_bucket(buckets, nil)
      assert_nil Spout::Helpers::ChartTypes::get_bucket(buckets, "m")
      assert_nil Spout::Helpers::ChartTypes::get_bucket(buckets, "1")
    end
  end
end
