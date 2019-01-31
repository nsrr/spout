# frozen_string_literal: true

# {
#   "id": "intake_questionnaire",
#   "display_name": "Intake Questionnaire at Baseline Visit",
#   "code_book": "Baseline-Visit-Intake-Questionnaire.pdf"
# }

require "spout/models/record"

module Spout
  module Models
    class Form < Spout::Models::Record
      attr_accessor :id, :folder, :display_name, :code_book
      attr_accessor :errors

      def initialize(file_name, dictionary_root)
        @errors = []
        @id     = file_name.to_s.gsub(/^(.*)\/|\.json$/, "").downcase
        @folder = file_name.to_s.gsub(/^#{dictionary_root}\/forms\/|#{@id}\.json$/, "")

        json = begin
          JSON.parse(File.read(file_name, encoding: "utf-8"))
        rescue => e
          form_name = file_name.to_s.gsub(/^(.*)\/|\.json$/, "").downcase
          @errors << "Error Parsing #{form_name}.json: #{e.message}"
          nil
        end

        if json.is_a? Hash
          %w(display_name code_book).each do |method|
            instance_variable_set("@#{method}", json[method])
          end

          @errors << "'id': #{json['id'].inspect} does not match filename #{@id.inspect}" if @id != json["id"]
        elsif json
          @errors << "Form must be a valid hash in the following format: {\n\"id\": \"FORM_ID\",\n  \"display_name\": \"FORM DISPLAY NAME\",\n  \"code_book\": \"FORMPDF.pdf\"\n}"
        end
      end

      def deploy_params
        { name: id, folder: folder.to_s.gsub(%r{/$}, ""),
          display_name: display_name, code_book: code_book,
          spout_version: Spout::VERSION::STRING }
      end
    end
  end
end
