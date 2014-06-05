require 'json'

module Spout
  module Models
    class Variable
      # VARIABLE_TYPES = ['choices', 'numeric', 'integer']

      attr_accessor :id, :folder, :display_name, :description, :type, :units, :labels, :commonly_used
      attr_accessor :domain_name, :form_names
      attr_accessor :domain, :forms
      attr_reader :errors

      def initialize(file_name, dictionary_root)
        @errors = []
        @id     = file_name.to_s.gsub(/^(.*)\/|\.json$/, '').downcase
        @folder = file_name.to_s.gsub(/^#{dictionary_root}\/variables\/|#{@id}\.json$/, '')


        json = begin
          JSON.parse(File.read(file_name))
        rescue => e
          error = e.message
          nil
        end

        if json and json.kind_of? Hash

          %w( display_name description type units commonly_used ).each do |method|
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
      end

      def print
        %w( id folder display_name description type units commonly_used domain_name form_names errors ).each do |method|
          puts "#{"%13s" % method}: #{self.send(method).inspect}"
        end
      end

      def path
        File.join(@folder, "#{@id}.json")
      end

    end
  end
end
