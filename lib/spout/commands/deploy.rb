require 'colorize'

require 'spout/helpers/config_reader'

# - **User Validation**
#   - User authenticates via token, the user must be a dataset editor
# - **Version Check**
#   - "v#{VERSION}" matches HEAD git tag annotation
#   - `CHANGELOG.md` top line should include version, ex: `## 0.1.0`
#   - Git Repo should have zero uncommitted changes
# - **Tests Pass**
#   - `spout t` passes for RC and FINAL versions (Include .rc, does not include .beta)
#   - `spout c` passes for RC and FINAL versions (Include .rc, does not include .beta)
# - **Graph Generation**
#   - `spout g` is run
#   - Graphs are pushed to server
# - **Image Generation**
#   - `spout p` is run
#   - `optipng` is run on image then uploaded to server
#   - Images are pushed to server
# - **Dataset Uploads**
#   - Dataset CSV data dictionary is generated (variables, domains, forms)
#   - Dataset and data dictionary CSVs uploaded to files section of dataset
# - **Server-Side Updates**
#   - Server checks out branch of specified tag
#   - Server runs `load_data_dictionary!` for specified dataset slug
#   - Server refreshes dataset folder to reflect new dataset and data dictionaries

module Spout
  module Commands
    class Deploy

      attr_accessor :token, :version, :slug, :url

      def initialize(argv)
        puts "CODE GREEN INITIALIZED...".colorize(:green)
        puts "Deploying to server...".colorize(:red)
        run_all
      end

      def run_all
        config_file_check
        user_authorization_check
        version_check
        test_check
        graph_generation
        image_generation
        dataset_uploads
        trigger_server_updates
      end

      def config_file_check
        puts "config_file_check".colorize(:blue)
      end

      def user_authorization_check
        puts "user_authorization_check".colorize(:blue)
      end

      def version_check
        puts "version_check".colorize(:blue)
      end

      def test_check
        puts "test_check".colorize(:blue)
      end

      def graph_generation
        puts "graph_generation".colorize(:blue)
      end

      def image_generation
        puts "image_generation".colorize(:blue)
      end

      def dataset_uploads
        puts "dataset_uploads".colorize(:blue)
      end

      def trigger_server_updates
        puts "trigger_server_updates".colorize(:blue)
      end

    end
  end
end
