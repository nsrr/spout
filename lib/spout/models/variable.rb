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
      attr_accessor :n, :mean, :stddev, :median, :min, :max, :unknown, :total
      attr_reader :errors

      def initialize(file_name, dictionary_root)
        @errors = []
        @id     = file_name.to_s.gsub(%r{^(.*)/|\.json$}, '').downcase
        @folder = file_name.to_s.gsub(%r{^#{dictionary_root}/variables/|#{@id}\.json$}, '')
        @form_names = []

        json = begin
                 JSON.parse(File.read(file_name))
               rescue => e
                 error = e.message
                 nil
               end

        if json.is_a? Hash
          %w(display_name description type units commonly_used calculation).each do |method|
            instance_variable_set("@#{method}", json[method])
          end
          @commonly_used = false if @commonly_used.nil?
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
        @forms = @form_names.collect { |form_name| Spout::Models::Form.find_by_id(form_name) }.compact
      end

      def path
        File.join(@folder, "#{@id}.json")
      end

      def known_issues
        line_found = false
        lines = []
        known_issues_file = 'KNOWNISSUES.md'
        if File.exist?(known_issues_file) && File.file?(known_issues_file)
          IO.foreach(known_issues_file) do |line|
            if line_found && Variable.starts_with?(line, '  - ')
              lines << line
            elsif Variable.partial_match?(line, "\\[#{id}\\]")
              line_found = true
              lines << line
            else
              line_found = false
            end
          end
        end
        lines.join("\n")
      end

      def self.starts_with?(string, term)
        !(/^#{term.to_s.downcase}/ =~ string.to_s.downcase).nil?
      end

      def self.partial_match?(string, term)
        !(/#{term.to_s.downcase}/ =~ string.to_s.downcase).nil?
      end

      def deploy_params
        { name: id, display_name: display_name, variable_type: type,
          folder: folder.to_s.gsub(%r{/$}, ''), description: description,
          units: units, calculation: calculation, commonly_used: commonly_used,
          labels: labels,
          stats_n: n, stats_mean: mean, stats_stddev: stddev,
          stats_median: median, stats_min: min, stats_max: max,
          stats_unknown: unknown, stats_total: total,
          known_issues: known_issues,
          spout_version: Spout::VERSION::STRING
        }
      end
    end
  end
end
