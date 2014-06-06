require 'spout/models/dictionary'

module Spout
  module Helpers
    module Iterators

      def self.included(c)
        class << c; attr_accessor :dictionary, :variables, :domains, :forms; end
        c.instance_variable_set(:@dictionary, Spout::Models::Dictionary.new(Dir.pwd).load_all!)
        c.instance_variable_set(:@variables, c.instance_variable_get(:@dictionary).variables)
        c.instance_variable_set(:@domains, c.instance_variable_get(:@dictionary).domains)
        c.instance_variable_set(:@forms, c.instance_variable_get(:@dictionary).forms)
      end

    end
  end
end
