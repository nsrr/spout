require 'artifice'
require 'uri'

module TestHelpers
  module Nsrr
    def app
      proc do |env|
        case "#{env['PATH_INFO']}?#{env['QUERY_STRING']}"
        when '/datasets/myrepo/a/1-abcd/editor.json?'
          [200, { 'Content-Type' => 'application/json' }, [{ editor: true, user_id: 1 }.to_json]]
        when '/api/v1/dictionary/refresh.json?auth_token=1-abcd&dataset=myrepo&version=1.0.0&folders[]=datasets&folders[]=datasets/archive&folders[]=datasets/archive/1.0.0'
          [200, { 'Content-Type' => 'application/json' }, [{ refresh: 'success' }.to_json]]
        when '/datasets/myrepo/a/3-ijkl/editor.json?'
          [200, { 'Content-Type' => 'application/json' }, [{ editor: true, user_id: 3 }.to_json]]
        when '/api/v1/dictionary/refresh.json?auth_token=3-ijkl&dataset=myrepo&version=1.0.0&folders[]=datasets&folders[]=datasets/archive&folders[]=datasets/archive/1.0.0'
          [200, { 'Content-Type' => 'application/json' }, [{ refresh: 'fail' }.to_json]]
        when '/datasets/myrepo/a/2-efgh/editor.json?'
          [200, { 'Content-Type' => 'application/json' }, [{ editor: false, user_id: 2 }.to_json]]
        when '/datasets/myrepo/a/_/editor.json?'
          [200, { 'Content-Type' => 'application/json' }, [{ editor: false, user_id: nil }.to_json]]
        else
          puts "env['PATH_INFO'] + env['QUERY_STRING']: #{env['PATH_INFO'] + env['QUERY_STRING']}"
          [200, { 'Content-Type' => 'application/json' }, []]
        end
      end
    end
  end
end
