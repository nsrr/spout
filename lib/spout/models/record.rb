require 'json'
require 'fileutils'

module Spout
  module Models
    # Base class for spout variables, forms, and domains that are read from JSON
    # files
    class Record
      class << self
        # Only returns records with zero json errors, nil otherwise
        def find_by_id(id)
          file_name = Dir.glob(expected_path(id), File::FNM_CASEFOLD).first
          variable = new(file_name, dictionary_root)
          (variable.errors.size > 0 ? nil : variable)
        end

        private

        def record_folder
          "#{name.split('::').last.to_s.downcase}s"
        end

        def expected_filename(id)
          "#{id.to_s.downcase}.json"
        end

        def expected_path(id)
          File.join(dictionary_root, record_folder, '**', expected_filename(id))
        end

        def dictionary_root
          FileUtils.pwd
        end
      end
    end
  end
end
