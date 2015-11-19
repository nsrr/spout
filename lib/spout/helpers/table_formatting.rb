module Spout
  module Helpers
    class TableFormatting
      # def initialize(number)
      #   @number = number
      # end

      def self.number_with_delimiter(number, delimiter = ',')
        number.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
      end

      # type:  :count    or   :decimal
      def self.format_number(number, type, format = nil)
        if number.nil?
          format_nil(number)
        elsif type == :count
          format_count(number)
        else
          format_decimal(number, format)
        end
      end

      def self.format_nil(number)
        '-'
      end

      #   count:
      #        0          ->             '-'
      #       10          ->            '10'
      #     1000          ->         '1,000'
      # Input (Numeric)   -> Output (String)
      def self.format_count(number)
        (number == 0 || number.nil?) ? '-' : number_with_delimiter(number)
      end

      # decimal:
      #        0          ->           '0.0'
      #       10          ->          '10.0'
      #      -50.2555     ->         '-50.3'
      #     1000          ->       '1,000.0'
      # 12412423.42252525 ->  '12,412,423.4'
      # Input (Numeric)   -> Output (String)
      def self.format_decimal(number, format)
        number = number_with_delimiter(number.round(1))
        number = format % number if format
        number
      end
    end
  end
end
