  # def dataset_folders
  #   Dir.entries('csvs').select{|e| File.directory? File.join('csvs', e) }.reject{|e| [".",".."].include?(e)}.sort
  # end
module Spout
  module Helpers

    class Version
      attr_accessor :string
      attr_reader :major, :minor, :tiny, :build

      def initialize(string)
        @string = string.to_s
        (@major, @minor, @tiny, @build) = @string.split('.')
      end

      def major_number
        @major.to_i
      end

      def minor_number
        @minor.to_i
      end

      def tiny_number
        @tiny.to_i
      end

      def build_number
        (@build == nil ? 1 : 0)
      end

      def rank
        [major_number, minor_number, tiny_number, build_number]
      end
    end

    class Semantic

      attr_accessor :data_dictionary_version

      def initialize(version, version_strings)
        @data_dictionary_version = Spout::Helpers::Version.new(version)
        @versions = version_strings.collect{ |vs| Spout::Helpers::Version.new(vs) }.sort_by(&:rank)
      end

      def valid_versions
        @versions.select{ |v| v.major == major and v.minor == minor }
      end

      def selected_folder
        if valid_versions.size == 0 or valid_versions.collect(&:string).include?(version)
          version
        else
          valid_versions.collect(&:string).last
        end
      end

      def version
        @data_dictionary_version.string
      end

      def major
        @data_dictionary_version.major
      end

      def minor
        @data_dictionary_version.minor
      end

      def tiny
        @data_dictionary_version.tiny
      end

      def build
        @data_dictionary_version.build
      end

    end

  end
end
