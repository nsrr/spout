require 'json'

require 'spout/models/record'
require 'spout/models/domain'
require 'spout/models/form'


module Spout
  module Models
    class Variable < Spout::Models::Record
      # VARIABLE_TYPES = ['choices', 'numeric', 'integer']

      attr_accessor :id, :folder, :display_name, :description, :type, :units, :labels, :commonly_used, :calculation
      attr_accessor :domain_name, :form_names
      attr_accessor :domain, :forms
      attr_reader :errors

      def initialize(file_name, dictionary_root)
        @errors = []
        @id     = file_name.to_s.gsub(/^(.*)\/|\.json$/, '').downcase
        @folder = file_name.to_s.gsub(/^#{dictionary_root}\/variables\/|#{@id}\.json$/, '')
        @form_names = []

        json = begin
          JSON.parse(File.read(file_name))
        rescue => e
          error = e.message
          nil
        end

        if json and json.is_a? Hash

          %w( display_name description type units commonly_used calculation ).each do |method|
            instance_variable_set("@#{method}", json[method])
          end

          @errors << "'id': #{json['id'].inspect} does not match filename #{@id.inspect}" if @id != json['id']

          @domain_name  = json['domain'] # Spout::Models::Domain.new(json['domain'], dictionary_root)
          @labels       = (json['labels'] || [])
          @form_names   = (json['forms'] || []).collect do |form_name|
            form_name
          end
        elsif json
          @errors << "Variable must be a valid hash in the following format: {\n\"id\": \"VARIABLE_ID\",\n  \"display_name\": \"VARIABLE DISPLAY NAME\",\n  \"description\": \"VARIABLE DESCRIPTION\"\n}"
        end

        @errors = (@errors + [error]).compact

        @domain = Spout::Models::Domain.find_by_id(@domain_name)
        @forms = @form_names.collect{|form_name| Spout::Models::Form.find_by_id(form_name)}.compact
      end

      def path
        File.join(@folder, "#{@id}.json")
      end

    end
  end
end
