# frozen_string_literal: true

module Spout
  module Models
    # Defines a continuous or discrete bucket for tables and graphs
    class Bucket
      attr_accessor :start, :stop

      def initialize(start, stop, discrete: false)
        @start = start
        @stop = stop
        @discrete = discrete
      end

      def in_bucket?(value)
        value >= @start && value <= @stop
      end

      def display_name
        return "#{@start}" if @discrete
        "#{@start} to #{@stop}"
      end
    end
  end
end
