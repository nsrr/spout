require 'openssl'
require 'net/http'
require 'json'

module Spout
  module Helpers
    class SendFile
      class << self
        def post(*args)
          new(*args).post
        end
      end

      attr_reader :url

      def initialize(url, filename, version, token, type = nil)

        @params = {}
        @params["version"] = version
        @params["auth_token"] = token if token
        @params["type"] = type if type
        begin
          file = File.open(filename, "rb")
          @params["file"] = file

          mp = Multipart::MultipartPost.new
          @query, @headers = mp.prepare_query(@params)
        ensure
          file.close if file
        end

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

      def post
        begin
          response = @http.start do |http|
            http.post(@url.path, @query, @headers)
          end
          JSON.parse(response.body)
        rescue
          nil
        end
      end
    end
  end
end


module Multipart
  class Param
    attr_accessor :k, :v
    def initialize( k, v )
      @k = k
      @v = v
    end

    def to_multipart
      return "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
    end
  end

  class FileParam
    attr_accessor :k, :filename, :content
    def initialize( k, filename, content )
      @k = k
      @filename = filename
      @content = content
    end

    def to_multipart
      mime_type = 'application/octet-stream'
      return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{mime_type}\r\n\r\n" + content + "\r\n"
    end
  end
  class MultipartPost
    BOUNDARY = 'a#41-93r1-^&#213-rule0000'
    HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " "}

    def prepare_query (params)
      fp = []
      params.each {|k,v|
        if v.respond_to?(:read)
          fp.push(FileParam.new(k, v.path, v.read))
        else
          fp.push(Param.new(k,v))
        end
      }
      query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
      return query, HEADER
    end
  end
end
