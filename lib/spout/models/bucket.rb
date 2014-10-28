module Spout
  module Models
    class Bucket

      attr_accessor :start, :stop

      def initialize(start, stop)
        @start = start
        @stop = stop
      end

      def in_bucket?(value)
        value >= @start and value <= @stop
      end

      def display_name
        "#{@start} to #{@stop}"
      end

    end
  end
end
