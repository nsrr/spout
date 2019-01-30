# frozen_string_literal: true

require "openssl"
require "net/http"
require "json"

module Spout
  module Helpers
    # Generates JSON web requests for POST and PATCH.
    class SendJson
      class << self
        def post(*args)
          new(*args).post
        end

        def patch(url, *args)
          new(url, *args).patch
        end
      end

      def initialize(url, args = {})
        @params = args
        @url = URI.parse(url)

        @http = Net::HTTP.new(@url.host, @url.port)
        if @url.scheme == "https"
          @http.use_ssl = true
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      rescue
        @error = "Invalid URL: #{url.inspect}"
        puts @error.red
      end

      def post
        return unless @error.nil?

        header = { "Content-Type" => "application/json", "Accept" => "application/json" }
        response = @http.start do |http|
          puts @params.to_json.white
          http.post(@url.path, @params.to_json, header)
        end
        [JSON.parse(response.body), response]
      rescue => e
        puts "POST ERROR".red
        puts e.to_s.white
        nil
      end

      def patch
        @params["_method"] = "patch"
        post
      end
    end
  end
end
