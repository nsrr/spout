module Spout
  module Models
    # Used for empty values, these values exist in that the column is defined
    # in the CSV, however the cell is blank. This is to differentiate this
    # value from nil, where the subject row exists, but the column for the
    # is not specified.
    class Empty
      def to_f
        self
      end

      def to_s
        'Empty'
      end
    end
  end
end
