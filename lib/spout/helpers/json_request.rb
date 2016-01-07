require 'openssl'
require 'net/http'
require 'json'

module Spout
  module Helpers
    class JsonRequest
      class << self
        def get(*args)
          new(*args).get
        end
      end

      attr_reader :url

      def initialize(url)
        begin
          @url = URI.parse(url)
          @http = Net::HTTP.new(@url.host, @url.port)
          if @url.scheme == 'https'
            @http.use_ssl = true
            @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
        rescue
        end
      end

      def get
        begin
          full_path = @url.path
          full_path += "?#{@url.query}" if @url.query
          req = Net::HTTP::Get.new(full_path)
          response = @http.start do |http|
            http.request(req)
          end
          JSON.parse(response.body)
        rescue
          nil
        end
      end
    end
  end
end
