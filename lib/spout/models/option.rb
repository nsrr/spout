module Spout
  module Models
    class Option
      attr_accessor :display_name, :value, :description, :missing

      def initialize(option_hash)
        %w( display_name value description missing ).each do |method|
          instance_variable_set("@#{method}", (option_hash.is_a?(Hash) ? option_hash : {})[method])
        end
      end

    end
  end
end
