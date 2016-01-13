require 'colorize'
require 'net/http'
require 'io/console'

require 'spout/helpers/subject_loader'
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
      INDENT = ' ' * INDENT_LENGTH

      attr_accessor :token, :version, :slug, :url, :config, :environment, :webserver_name, :subjects

      def initialize(argv, version)
        argv.shift # Remove 'download' command from argv list
        @environment = argv.shift
        @version = version
        @skip_checks = !(argv.delete('--skip-checks').nil? && argv.delete('--no-checks').nil?)

        @skip_variables = !(argv.delete('--skip-variables').nil? && argv.delete('--no-variables').nil?)
        @skip_dataset = !(argv.delete('--skip-dataset').nil? && argv.delete('--no-dataset').nil?)
        @skip_dictionary = !(argv.delete('--skip-dictionary').nil? && argv.delete('--no-dictionary').nil?)
        @skip_documentation = !(argv.delete('--skip-documentation').nil? && argv.delete('--no-documentation').nil?)
        @clean = !(argv.delete('--no-resume').nil? && argv.delete('--clean').nil?)
        @skip_server_scripts = !(argv.delete('--skip-server-scripts').nil? && argv.delete('--no-server-scripts').nil?)
        @archive_only = !(argv.delete('--archive-only').nil?)

        token_arg = argv.find { |arg| /^--token=/ =~ arg }
        argv.delete(token_arg)
        @token = token_arg.gsub(/^--token=/, '') if token_arg

        rows_arg = argv.find { |arg| /^--rows=(\d*)/ =~ arg }
        argv.delete(rows_arg)
        @number_of_rows = rows_arg.gsub(/--rows=/, '').to_i if rows_arg

        @argv = argv

        begin
          run_all
        rescue Interrupt
          puts "\nINTERRUPTED".colorize(:red)
        end
      end

      def run_all
        config_file_load
        version_check
        test_check
        user_authorization
        upload_variables
        dataset_uploads
        data_dictionary_uploads
        markdown_uploads
        trigger_server_updates
      rescue DeployError
        # Nothing on Deploy Error
      end

      def config_file_load
        print '   `.spout.yml` Check: '
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

        matching_webservers = @config.webservers.select { |wh| /^#{@environment}/i =~ wh['name'].to_s.downcase }
        if matching_webservers.count == 0
          message = "#{INDENT}0 webservers match '#{@environment}'.".colorize(:red) + " The following webservers exist in your `.spout.yml` file:\n" + "#{INDENT}#{@config.webservers.collect{|wh| wh['name'].to_s.downcase}.join(', ')}".colorize(:white)
          failure(message)
        elsif matching_webservers.count > 1
          message = "#{INDENT}#{matching_webservers.count} webservers match '#{@environment}'.".colorize(:red) + " Did you mean one of the following?\n" + "#{INDENT}#{matching_webservers.collect{|wh| wh['name'].to_s.downcase}.join(', ')}".colorize(:white)
          failure(message)
        end

        @webserver_name = matching_webservers.first['name'].to_s.strip rescue @webserver_name = ''
        @url = URI.parse(matching_webservers.first['url'].to_s.strip) rescue @url = nil

        if @url.to_s == ''
          message = "#{INDENT}Invalid URL format for #{matching_webservers.first['name'].to_s.strip.downcase} webserver: ".colorize(:red) + "'#{matching_webservers.first['url'].to_s.strip}'".colorize(:white)
          failure(message)
        end

        puts 'PASS'.colorize(:green)
        puts '        Target Server: ' + "#{@url}".colorize(:white)
        puts '       Target Dataset: ' + "#{@slug}".colorize(:white)
      end

      # - **Version Check**
      #   - Git Repo should have zero uncommitted changes
      #   - `CHANGELOG.md` top line should include version, ex: `## 0.1.0`
      #   - "v#{VERSION}" matches HEAD git tag annotation
      def version_check
        if @skip_checks
          puts '        Version Check: ' + 'SKIP'.colorize(:blue)
          return
        end

        stdout = quietly do
          `git status --porcelain`
        end

        print '     Git Status Check: '
        if stdout.to_s.strip == ''
          puts 'PASS'.colorize(:green) + ' ' + 'nothing to commit, working directory clean'.colorize(:white)
        else
          message = "#{INDENT}working directory contains uncomitted changes\n#{INDENT}use `".colorize(:red) + '--skip-checks'.colorize(:white) + '` to ignore this step'.colorize(:red)
          failure message
        end

        changelog = File.open('CHANGELOG.md', &:readline).strip rescue changelog = ''
        if changelog.match(/^## #{@version.split('.')[0..2].join('.')}/)
          puts "         CHANGELOG.md: " + "PASS".colorize(:green) + " " + changelog.colorize(:white)
        else
          print '         CHANGELOG.md: '
          message = "#{INDENT}Expected: ".colorize(:red) + "## #{@version}".colorize(:white) +
                  "\n#{INDENT}  Actual: ".colorize(:red) + changelog.colorize(:white)
          failure message
        end

        stdout = quietly do
          `git describe --exact-match HEAD --tags`
        end

        print '        Version Check: '
        tag = stdout.to_s.strip
        if "v#{@version}" != tag
          message = "#{INDENT}Version specified in `VERSION` file ".colorize(:red) + "'v#{@version}'".colorize(:white) + ' does not match git tag on HEAD commit '.colorize(:red) + "'#{tag}'".colorize(:white)
          failure message
        else
          puts 'PASS'.colorize(:green) + ' VERSION ' + "'v#{@version}'".colorize(:white) + ' matches git tag ' + "'#{tag}'".colorize(:white)
        end
      end

      def test_check
        if @skip_checks
          puts '          Spout Tests: ' + 'SKIP'.colorize(:blue)
          return
        end

        print "          Spout Tests: "

        stdout = quietly do
          `spout t`
        end

        if stdout.match(/[^\d]0 failures, 0 errors,/)
          puts 'PASS'.colorize(:green)
        else
          message = "#{INDENT}spout t".colorize(:white) + " had errors or failures".colorize(:red) + "\n#{INDENT}Please fix all errors and failures and then run spout deploy again."
          failure message
        end

        puts '       Spout Coverage: ' + 'SKIP'.colorize(:blue)
      end

      def user_authorization
        puts  "  Get your token here: " + "#{@url}/token".colorize(:blue).on_white.underline
        print "     Enter your token: "
        @token = STDIN.noecho(&:gets).chomp if @token.to_s.strip == ''

        response = Spout::Helpers::JsonRequest.get("#{@url}/datasets/#{@slug}/a/#{@token}/editor.json")

        if response.is_a?(Hash) and response['editor']
          puts 'AUTHORIZED'.colorize(:green)
        else
          puts 'UNAUTHORIZED'.colorize(:red)
          puts "#{INDENT}You are not set as an editor on the #{@slug} dataset or you mistyped your token."
          fail DeployError
        end

        # failure ''
        # puts 'PASS'.colorize(:green)
      end

      def upload_variables
        if @skip_variables
          puts '     Upload Variables: ' + 'SKIP'.colorize(:blue)
          return
        end
        load_subjects_from_csvs
        graph_generation
      end

      def load_subjects_from_csvs
        @dictionary_root = Dir.pwd
        @variable_files = Dir.glob(File.join(@dictionary_root, 'variables', '**', '*.json'))
        @subject_loader = Spout::Helpers::SubjectLoader.new(@variable_files, [], @version, @number_of_rows, @config.visit)
        @subject_loader.load_subjects_from_csvs!
        @subjects = @subject_loader.subjects
      end

      def graph_generation
        # failure ''
        require 'spout/commands/graphs'
        @argv << '--clean' if @clean
        Spout::Commands::Graphs.new(@argv, @version, true, @url, @slug, @token, @webserver_name, @subjects)
        puts "\r     Upload Variables: " + 'DONE          '.colorize(:green)
      end

      def dataset_uploads
        if @skip_dataset
          puts '      Dataset Uploads: ' + 'SKIP'.colorize(:blue)
          return
        end

        available_folders = (Dir.exist?('csvs') ? Dir.entries('csvs').select { |e| File.directory? File.join('csvs', e) }.reject { |e| ['.', '..'].include?(e) }.sort : [])
        semantic = Spout::Helpers::Semantic.new(@version, available_folders)
        csv_directory = semantic.selected_folder
        csv_files = Dir.glob("csvs/#{csv_directory}/**/*.csv")

        csv_files.each_with_index do |csv_file, index|
          print "\r      Dataset Uploads: " + "#{index + 1} of #{csv_files.count}".colorize(:green)
          upload_file(csv_file, 'datasets') unless @archive_only
          upload_file(csv_file, "datasets/archive/#{@version}")
        end
        puts "\r      Dataset Uploads: " + 'DONE          '.colorize(:green)
      end

      def data_dictionary_uploads
        if @skip_dictionary
          puts '   Dictionary Uploads: ' + 'SKIP'.colorize(:blue)
          return
        end

        print '   Dictionary Uploads:'

        require 'spout/commands/exporter'
        Spout::Commands::Exporter.new(@version, ['--quiet'])

        csv_files = Dir.glob("dd/#{@version}/*.csv")
        csv_files.each_with_index do |csv_file, index|
          print "\r   Dictionary Uploads: " + "#{index + 1} of #{csv_files.count}".colorize(:green)
          upload_file(csv_file, 'datasets') unless @archive_only
          upload_file(csv_file, "datasets/archive/#{@version}")
        end
        puts "\r   Dictionary Uploads: " + 'DONE          '.colorize(:green)
      end

      def markdown_uploads
        if @skip_documentation
          puts 'Documentation Uploads: ' + 'SKIP'.colorize(:blue)
          return
        end

        print 'Documentation Uploads:'
        markdown_files = Dir.glob(%w(CHANGELOG.md KNOWNISSUES.md))
        markdown_files.each_with_index do |markdown_file, index|
          print "\rDocumentation Uploads: " + "#{index + 1} of #{markdown_files.count}".colorize(:green)
          upload_file(markdown_file, 'datasets') unless @archive_only
          upload_file(markdown_file, "datasets/archive/#{@version}")
        end
        puts "\rDocumentation Uploads: " + 'DONE          '.colorize(:green)
      end

      def trigger_server_updates
        if @skip_server_scripts
          puts 'Launch Server Scripts: ' + 'SKIP'.colorize(:blue)
          return
        end

        print 'Launch Server Scripts: '
        response = Spout::Helpers::JsonRequest.get("#{@url}/api/v1/dictionary/refresh.json?auth_token=#{@token}&dataset=#{@slug}&version=#{@version}&folders[]=datasets&folders[]=datasets/archive&folders[]=datasets/archive/#{@version}")
        if response.is_a?(Hash) && response['refresh'] == 'success'
          puts 'DONE'.colorize(:green)
        else
          puts 'FAIL'.colorize(:red)
          fail DeployError
        end
      end

      def failure(message)
        puts 'FAIL'.colorize(:red)
        puts message
        fail DeployError
      end

      def upload_file(file, folder)
        Spout::Helpers::SendFile.post("#{@url}/api/v1/dictionary/upload_file.json", file, @version, @token, @slug, folder)
      end
    end
  end
end
