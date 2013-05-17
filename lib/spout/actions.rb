module Spout
  class Actions

    def interpret(argv)
      case argv.first
      when 'new', 'n', 'ne', '-new', '-n', '-ne'
        new_template_dictionary(argv)
      when '--version', '-v', '-ve', '-ver', 'version', 'v', 've', 'ver'
        puts "Spout #{Spout::VERSION::STRING}"
      when 'test', 't', 'te', 'tes', '--test', '-t', '-te', '-tes'
        system "bundle exec rake"
      when 'import', 'i', 'im', 'imp', '--import', '-i', '-im', '-imp'
        import_from_csv(argv)
      when 'export', 'e', 'ex', 'exp', '--export', '-e', '-ex', '-exp'
        new_data_dictionary_export(argv)
      else
        help
      end
    end

    protected

      def import_from_csv(argv)
        usage = <<-EOT

Usage: spout import CSVFILE

The CSVFILE must be the location of a valid CSV file.

EOT

        csv_file = File.join(argv[1].to_s.strip)
        if File.exists?(csv_file)
          system "bundle exec rake dd:import CSV=#{csv_file}"
        else
          puts usage
        end
      end

      def help
        help_message = <<-EOT

Usage: spout COMMAND [ARGS]

The most common spout commands are:
  [n]ew       Create a new Spout dictionary. "spout new my_dd" creates a
              new data dictionary called MyDD in "./my_dd"
  [t]est      Running the test file
  [i]mport    Import a CSV file into the JSON repository
  [e]xport    Export the JSON respository to a CSV
  [v]ersion   Returns the version of Spout

Each command can be referenced by the first letter: Ex: `spout t`, for test

EOT
        puts help_message
      end

      def new_data_dictionary_export(argv)
        version = argv[1].to_s.gsub(/[^a-zA-Z0-9\.-]/, '_').strip
        version_string = (version == '' ? "" : "VERSION=#{version}")
        system "bundle exec rake dd:create #{version_string}"
      end

      def new_template_dictionary(argv)
        @full_path = File.join(argv[1].to_s.strip)
        usage = <<-EOT

Usage: spout new FOLDER

The FOLDER must be empty or new.

EOT

        if @full_path == '' or (Dir.exists?(@full_path) and (Dir.entries(@full_path) - ['.', '..']).size > 0)
          puts usage
          exit(0)
        end

        FileUtils.mkpath(@full_path)

        copy_file 'gitignore', '.gitignore'
        copy_file 'ruby-version', '.ruby-version'
        copy_file 'travis.yml', '.travis.yml'
        copy_file 'Gemfile'
        copy_file 'Rakefile'
        directory 'domains'
        directory 'variables'
        directory 'test'
        copy_file 'test/dictionary_test.rb'
        copy_file 'test/test_helper.rb'
        puts "         run  bundle install"
        Dir.chdir(@full_path)
        system "bundle install"
      end

    private

      def copy_file(template_file, file_name = '')
        file_name = template_file if file_name == ''
        file_path = File.join(@full_path, file_name)
        template_file_path = File.join(File.expand_path(File.dirname(__FILE__)), "templates", template_file)
        puts "      create  #{file_name}"
        FileUtils.copy(template_file_path, file_path)
      end

      def directory(directory_name)
        directory_path = File.join(@full_path, directory_name)
        puts "      create  #{directory_name}"
        FileUtils.mkpath(directory_path)
      end

  end
end
