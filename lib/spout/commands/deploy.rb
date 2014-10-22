require 'colorize'
require 'net/http'
require 'io/console'

require 'spout/helpers/config_reader'
require 'spout/helpers/quietly'
require 'spout/helpers/send_file'
require 'spout/helpers/semantic'
require 'spout/helpers/json_request'

# - **User Authorization**
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

class DeployError < StandardError
end

module Spout
  module Commands
    class Deploy

      include Spout::Helpers::Quietly

      INDENT_LENGTH = 23
      INDENT = " "*INDENT_LENGTH

      attr_accessor :token, :version, :slug, :url, :config, :environment

      def initialize(argv, version)
        @environment = argv[1].to_s
        @version = version
        @skip_checks = (argv.delete('--skip-checks') != nil or argv.delete('--no-checks') != nil)

        @skip_graphs = (argv.delete('--skip-graphs') != nil or argv.delete('--no-graphs') != nil)
        @skip_images = (argv.delete('--skip-images') != nil or argv.delete('--no-images') != nil)
        @skip_server_updates = (argv.delete('--skip-server-updates') != nil or argv.delete('--no-server-updates') != nil)

        @token = argv.select{|a| /^--token=/ =~ a}.collect{|a| a.gsub(/^--token=/, '')}.first

        run_all
      end

      def run_all
        begin
          config_file_load
          version_check unless @skip_checks
          test_check unless @skip_checks
          user_authorization
          graph_generation unless @skip_graphs
          image_generation unless @skip_images
          dataset_uploads
          data_dictionary_uploads
          trigger_server_updates unless @skip_server_updates
        rescue DeployError
        end
      end

      def config_file_load
        print "   `.spout.yml` Check: "
        @config = Spout::Helpers::ConfigReader.new

        @slug = @config.slug

        if @slug == ''
          message = "#{INDENT}Please specify a dataset slug in your `.spout.yml` file!".colorize(:red) + " Ex:\n---\nslug: mydataset\n".colorize(:orange)
          failure(message)
        end

        if @config.webservers.empty?
          message = "#{INDENT}Please specify a webserver in your `.spout.yml` file!".colorize(:red) + " Ex:\n---\nwebservers:\n  - name: production\n    url: https://sleepdata.org\n  - name: staging\n    url: https://staging.sleepdata.org\n".colorize(:orange)
          failure(message)
        end

        matching_webservers = @config.webservers.select{|wh| /^#{@environment}/i =~ wh['name'].to_s.downcase}
        if matching_webservers.count == 0
          message = "#{INDENT}0 webservers match '#{@environment}'.".colorize(:red) + " The following webservers exist in your `.spout.yml` file:\n" + "#{INDENT}#{@config.webservers.collect{|wh| wh['name'].to_s.downcase}.join(', ')}".colorize(:white)
          failure(message)
        elsif matching_webservers.count > 1
          message = "#{INDENT}#{matching_webservers.count} webservers match '#{@environment}'.".colorize(:red) + " Did you mean one of the following?\n" + "#{INDENT}#{matching_webservers.collect{|wh| wh['name'].to_s.downcase}.join(', ')}".colorize(:white)
          failure(message)
        end

        @url = URI.parse(matching_webservers.first['url'].to_s.strip) rescue @url = nil

        if @url.to_s == ''
          message = "#{INDENT}Invalid URL format for #{matching_webservers.first['name'].to_s.strip.downcase} webserver: ".colorize(:red) + "'#{matching_webservers.first['url'].to_s.strip}'".colorize(:white)
          failure(message)
        end

        puts "PASS".colorize(:green)
        puts "        Target Server: " + "#{@url}".colorize(:white)
        puts "       Target Dataset: " + "#{@slug}".colorize(:white)
      end

      # - **Version Check**
      #   - Git Repo should have zero uncommitted changes
      #   - `CHANGELOG.md` top line should include version, ex: `## 0.1.0`
      #   - "v#{VERSION}" matches HEAD git tag annotation
      def version_check
        stdout = quietly do
          `git status --porcelain`
        end

        print "     Git Status Check: "
        if stdout.to_s.strip == ''
          puts "PASS".colorize(:green) + " " + "nothing to commit, working directory clean".colorize(:white)
        else
          message = "#{INDENT}working directory contains uncomitted changes".colorize(:red)
          failure message
        end

        changelog = File.open('CHANGELOG.md', &:readline).strip rescue changelog = ''
        if changelog.match(/^## #{@version.split('.')[0..2].join('.')}/)
          puts "         CHANGELOG.md: " + "PASS".colorize(:green) + " " + changelog.colorize(:white)
        else
          print "         CHANGELOG.md: "
          message = "#{INDENT}Expected: ".colorize(:red) + "## #{@version}".colorize(:white) +
                  "\n#{INDENT}  Actual: ".colorize(:red) + changelog.colorize(:white)
          failure message
        end

        stdout = quietly do
          `git describe --exact-match HEAD`
        end

        print "        Version Check: "
        tag = stdout.to_s.strip
        if "v#{@version}" != tag
          message = "#{INDENT}Version specified in `VERSION` file ".colorize(:red) + "'v#{@version}'".colorize(:white) + " does not match git tag on HEAD commit ".colorize(:red) + "'#{tag}'".colorize(:white)
          failure message
        else
          puts   "PASS".colorize(:green) + " VERSION " + "'v#{@version}'".colorize(:white) + " matches git tag " + "'#{tag}'".colorize(:white)
        end

      end

      def test_check
        print "          Spout Tests: "

        stdout = quietly do
          `spout t`
        end

        if stdout.match(/[^\d]0 failures, 0 errors,/)
          puts "PASS".colorize(:green)
        else
          message = "#{INDENT}spout t".colorize(:white) + " had errors or failures".colorize(:red) + "\n#{INDENT}Please fix all errors and failures and then run spout deploy again."
          failure message
        end

        puts "       Spout Coverage: " + "SKIP".colorize(:blue)
      end

      def user_authorization
        puts  "  Get your token here: " + "#{@url}/token".colorize(:blue).on_white.underline
        print "     Enter your token: "
        @token = STDIN.noecho(&:gets).chomp if @token.to_s.strip == ''

        response = Spout::Helpers::JsonRequest.get("#{@url}/datasets/#{@slug}/a/#{@token}/editor.json")

        if response.kind_of?(Hash) and response['editor']
          puts "AUTHORIZED".colorize(:green)
        else
          puts "UNAUTHORIZED".colorize(:red)
          puts "#{INDENT}You are not set as an editor on the #{@slug} dataset or you mistyped your token."
          raise DeployError
        end

        # failure ''
        # puts "PASS".colorize(:green)
      end

      def graph_generation
        # failure ''
        require 'spout/commands/graphs'
        Spout::Commands::Graphs.new([], @version, true, @url, @slug, @token)
        puts "\r     Graph Generation: " + "DONE          ".colorize(:green)
      end

      def image_generation
        # failure ''
        require 'spout/commands/images'
        Spout::Commands::Images.new([], [], [], @version, [], true, @url, @slug, @token)
        puts "\r     Image Generation: " + "DONE          ".colorize(:green)
      end

      def dataset_uploads
        available_folders = (Dir.exist?('csvs') ? Dir.entries('csvs').select{|e| File.directory? File.join('csvs', e) }.reject{|e| [".",".."].include?(e)}.sort : [])
        semantic = Spout::Helpers::Semantic.new(@version, available_folders)
        csv_directory = semantic.selected_folder

        if @version != csv_directory
          puts "\r      Dataset Uploads: " + "SKIPPED - #{csv_directory} CSV dataset already on server".colorize(:blue)
          return
        end

        csv_files = Dir.glob("csvs/#{csv_directory}/*.csv")

        csv_files.each_with_index do |csv_file, index|
          print "\r      Dataset Uploads: " + "#{index + 1} of #{csv_files.count}".colorize(:green)
          response = Spout::Helpers::SendFile.post("#{@url}/datasets/#{@slug}/upload_dataset_csv.json", csv_file, @version, @token)
        end
        puts "\r      Dataset Uploads: " + "DONE          ".colorize(:green)
      end

      def data_dictionary_uploads
        print   "   Dictionary Uploads:"

        require 'spout/commands/exporter'
        Spout::Commands::Exporter.new(@version, ['--quiet'])

        csv_files = Dir.glob("dd/#{@version}/*.csv")
        csv_files.each_with_index do |csv_file, index|
          print "\r   Dictionary Uploads: " + "#{index + 1} of #{csv_files.count}".colorize(:green)
          response = Spout::Helpers::SendFile.post("#{@url}/datasets/#{@slug}/upload_dataset_csv.json", csv_file, @version, @token)
        end
        puts "\r   Dictionary Uploads: " + "DONE          ".colorize(:green)
      end

      def trigger_server_updates
        print "Launch Server Scripts: "
        response = Spout::Helpers::JsonRequest.get("#{@url}/datasets/#{@slug}/a/#{@token}/refresh_dictionary.json?version=#{@version}")
        if response.kind_of?(Hash) and response['refresh'] == 'success'
          puts "DONE".colorize(:green)
        elsif response.kind_of?(Hash) and response['refresh'] == 'notagfound'
          puts "FAIL".colorize(:red)
          puts "#{INDENT}Tag not found in repository, resolve using: " + "git push --tags".colorize(:white)
          raise DeployError
        elsif response.kind_of?(Hash) and response['refresh'] == 'gitrepodoesnotexist'
          puts "FAIL".colorize(:red)
          puts "#{INDENT}Dataset data dictionary git repository has not been cloned on the server. Contact server admin.".colorize(:white)
          raise DeployError
        else
          puts "FAIL".colorize(:red)
          raise DeployError
        end
      end

      def failure(message)
        puts "FAIL".colorize(:red)
        puts message
        raise DeployError
      end
    end
  end
end
