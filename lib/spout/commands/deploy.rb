require 'colorize'
require 'net/http'

require 'spout/helpers/config_reader'

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

      INDENT_LENGTH = 23
      INDENT = " "*INDENT_LENGTH

      attr_accessor :token, :version, :slug, :url, :config, :environment

      def initialize(argv, version)
        # puts "CODE GREEN INITIALIZED...".colorize(:green)
        # puts "Deploying to server...".colorize(:red)
        @environment = argv[1].to_s
        @version = version
        run_all
      end

      def run_all
        begin
          config_file_check
          version_check
          test_check
          user_authorization_check
          graph_generation
          image_generation
          dataset_uploads
          trigger_server_updates
        rescue DeployError
        end
      end

      def config_file_check
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
        stdout = `git status --porcelain`

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

        stdout = `git describe --exact-match HEAD`

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
        failure ''
        puts "PASS".colorize(:green)
      end

      def user_authorization_check
        print "   User Authorization: "
        # failure ''
        # puts "PASS".colorize(:green)
        puts "SKIP".colorize(:blue)
      end

      def graph_generation
        print "     Graph Generation: "
        failure ''
        puts "PASS".colorize(:green)
      end

      def image_generation
        print "     Image Generation: "
        failure ''
        puts "PASS".colorize(:green)
      end

      def dataset_uploads
        print "      Dataset Uploads: "
        failure ''
        puts "PASS".colorize(:green)
      end

      def trigger_server_updates
        print "Launch Server Scripts: "
        failure ''
        puts "PASS".colorize(:green)
      end

      def failure(message)
        puts "FAIL".colorize(:red)
        puts message
        raise DeployError
      end

    end
  end
end
