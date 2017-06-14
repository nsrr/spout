# frozen_string_literal: true

module Spout
  module Helpers
    module NumberHelper
      def number_with_delimiter(number, delimiter = ",")
        number.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(",").reverse
      end
    end
  end
end
