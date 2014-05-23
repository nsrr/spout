# subject.rb

module Spout
  module Models

    class Subject
      attr_accessor :_visit

      def self.create(&block)
        subject = self.new
        yield subject if block_given?
        subject
      end

    end
  end
end
