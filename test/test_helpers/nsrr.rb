require 'artifice'
require 'uri'

module TestHelpers
  module Nsrr
    def app
      proc do |env|
        case env["PATH_INFO"]
        when "/datasets/myrepo/a/1-abcd/editor.json"
          [200, { 'Content-Type' => 'application/json' }, [{ editor: true, user_id: 1 }.to_json]]
        when "/datasets/myrepo/a/1-abcd/refresh_dictionary.json"
          [200, { 'Content-Type' => 'application/json' }, [{ refresh: 'success' }.to_json]]
        when "/datasets/myrepo/a/3-ijkl/editor.json"
          [200, { 'Content-Type' => 'application/json' }, [{ editor: true, user_id: 3 }.to_json]]
        when "/datasets/myrepo/a/3-ijkl/refresh_dictionary.json"
          [200, { 'Content-Type' => 'application/json' }, [{ refresh: 'fail' }.to_json]]
        when "/datasets/myrepo/a/4-mnop/editor.json"
          [200, { 'Content-Type' => 'application/json' }, [{ editor: true, user_id: 4 }.to_json]]
        when "/datasets/myrepo/a/4-mnop/refresh_dictionary.json"
          [200, { 'Content-Type' => 'application/json' }, [{ refresh: 'notagfound' }.to_json]]
        when "/datasets/myrepo/a/2-efgh/editor.json"
          [200, { 'Content-Type' => 'application/json' }, [{ editor: false, user_id: 2 }.to_json]]
        when "/datasets/myrepo/a/_/editor.json"
          [200, { 'Content-Type' => 'application/json' }, [{ editor: false, user_id: nil }.to_json]]
        else
          [200, { 'Content-Type' => 'application/json' }, []]
        end
      end
    end
  end
end
