# frozen_string_literal: true

require "json"

def json_value(file, key)
  begin JSON.parse(File.read(file, encoding: "utf-8"))[key.to_s] rescue nil end
end
