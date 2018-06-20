# frozen_string_literal: true

module Spout
  module Helpers
    # Provides method to format large numbers with delimiters.
    module NumberHelper
      def number_with_delimiter(number, delimiter = ",")
        number.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(delimiter).reverse
      end

      module_function :number_with_delimiter
    end
  end
end
