require 'json'
require 'fileutils'

module Spout
  module Models
    class Record

      class << self
        # Only returns records with zero json errors, nil otherwise
        def find_by_id(id)
          dictionary_root = FileUtils.pwd # '.'
          file_name = Dir.glob(File.join(dictionary_root, "#{self.name.split("::").last.to_s.downcase}s", "**", "#{id.to_s.downcase}.json"), File::FNM_CASEFOLD).first
          variable = new(file_name, dictionary_root)
          (variable.errors.size > 0 ? nil : variable)
        end
      end
    end
  end
end
