module Spout
  module Helpers
    class JsonLoader

      def self.get_json(file_name, file_type)
        file = Dir.glob("#{file_type}s/**/#{file_name}.json").first
        json = JSON.parse(File.read(file)) rescue json = nil
        json
      end

      def self.get_variable(variable_name)
        get_json(variable_name, 'variable')
      end

    end
  end
end
