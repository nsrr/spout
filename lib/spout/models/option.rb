module Spout
  module Models
    class Option
      attr_accessor :display_name, :value, :description

      def initialize(option_hash)
        %w( display_name value description ).each do |method|
          instance_variable_set("@#{method}", (option_hash.kind_of?(Hash) ? option_hash : {})[method])
        end
      end

    end
  end
end
