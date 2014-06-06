require 'test_helper'

class DictionaryTest < Minitest::Test
  # This line includes all default Spout Dictionary tests
  include Spout::Tests

  # This line provides access to @variables, @forms, and @domains iterators
  # iterators that can be used to write custom tests
  include Spout::Helpers::Iterators

  # Example 1: Create custom tests to show that `integer` and `numeric` variables have a valid unit type
  # VALID_UNITS = ['minutes', 'hours'] # Add your own valid units to this array
  # @variables.select{|v| v.type == 'numeric' or v.type == 'integer'}.each do |variable|
  #   define_method("test_units: "+variable.path) do
  #     message = "\"#{variable.units}\"".colorize( :red ) + " invalid units.\n" +
  #               "             Valid types: " +
  #               VALID_UNITS.sort.collect{|u| u.inspect.colorize( :white )}.join(', ')
  #     assert VALID_UNITS.include?(variable.units), message
  #   end
  # end

  # Example 2: Create custom tests to show that variables have 2 or more labels.
  # @variables.select{|v| ['numeric','integer'].include?(v.type)}.each do |variable|
  #   define_method("test_at_least_two_labels: "+variable.path) do
  #     assert_operator 2, :<=, variable.labels.size
  #   end
  # end

  # Example 3: Create regular Ruby tests
  # You may add additional tests here
  # def test_truth
  #   assert true
  # end
end
