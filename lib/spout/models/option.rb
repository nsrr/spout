# frozen_string_literal: true

module Spout
  module Models
    class Option
      attr_accessor :display_name, :value, :description, :missing

      def initialize(option_hash)
        %w(display_name value description missing).each do |method|
          instance_variable_set("@#{method}", (option_hash.is_a?(Hash) ? option_hash : {})[method])
        end
      end

      def deploy_params
        { display_name: display_name, value: value, description: description,
          missing: missing }
      end
    end
  end
end
