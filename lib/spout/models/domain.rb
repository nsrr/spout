require 'json'

require 'spout/models/option'

module Spout
  module Models

    class Domain
      attr_accessor :id, :folder, :options
      attr_reader :errors

      def initialize(file_name, dictionary_root)
        @errors = []
        @id = file_name.to_s.gsub(/^(.*)\/|\.json$/, '').downcase

        @folder = file_name.to_s.gsub(/^#{dictionary_root}\/domains\/|#{@id}\.json$/, '')
        @options = []

        json = begin
          if File.exists?(file_name)
            JSON.parse(File.read(file_name))
          else
            @errors << "No corresponding #{@id}.json file found."
            nil
          end
        rescue => e
          @errors << "Parsing error found in #{@id}.json: #{e.message}" if file_name != nil
          nil
        end

        if json and json.kind_of? Array
          @id = file_name.to_s.gsub(/^(.*)\/|\.json$/, '').downcase
          @options = (json || []).collect do |option|
            Spout::Models::Option.new(option)
          end
        elsif json
          @errors << "Domain must be a valid array in the following format: [\n  {\n    \"value\": \"1\",\n    \"display_name\": \"First Choice\",\n    \"description\": \"First Description\"\n  },\n  {\n    \"value\": \"2\",\n    \"display_name\": \"Second Choice\",\n    \"description\": \"Second Description\"\n  }\n]"
        end

      end


    end
  end
end
