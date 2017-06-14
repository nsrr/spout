# frozen_string_literal: true

require "spout/models/variable"
require "spout/models/domain"
require "spout/models/form"

module Spout
  module Models
    # Creates a structure that contains a dictionaries variables, domains, and
    # forms
    class Dictionary
      attr_accessor :variables, :domains, :forms
      attr_accessor :app_path

      attr_reader :variable_files, :domain_files, :form_files

      def initialize(app_path)
        @app_path = app_path

        @variable_files = json_files("variables")
        @domain_files = json_files("domains")
        @form_files = json_files("forms")

        @variables = []
        @domains = []
        @forms = []
      end

      def load_all!
        load_variables!
        load_domains!
        load_forms!
        self
      end

      def load_variables!
        load_type!("Variable")
      end

      def load_domains!
        load_type!("Domain")
      end

      def load_forms!
        load_type!("Form")
      end

      private

      def json_files(type)
        Dir.glob(File.join(@app_path, type, "**", "*.json"))
      end

      def load_type!(method)
        results = instance_variable_get("@#{method.downcase}_files").collect do |file|
          Object.const_get("Spout::Models::#{method}").new(file, @app_path)
        end

        instance_variable_set("@#{method.downcase}s", results)
      end
    end
  end
end
