module Spout
  module Models
    # Subject encapsulates records for individuals specified by an identifier
    class Subject
      attr_accessor :_visit, :_csv

      def self.create
        subject = new
        yield subject if block_given?
        subject
      end
    end
  end
end
