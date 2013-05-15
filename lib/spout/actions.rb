module Spout
  class Actions

    def help
      help_message = <<-EOT

Usage: spout COMMAND [ARGS]

The most common spout commands are:
  test        Running the test file (short-cut alias: "t")
  new         Create a new Spout dictionary. "spout new my_dd" creates a
              new data dictionary called MyDD in "./my_dd"
  version     Returns the version of Spout

EOT
      puts help_message
    end

    def interpret(argv)
      case argv.first
      when 'new'
        new_template_dictionary(argv)
      when '--version', '-v', 'version'
        puts "Spout #{Spout::VERSION::STRING}"
      when 'help', '--help', '-h'
        help
      else
        system "bundle exec rake"
      end
    end

    def new_template_dictionary(argv)
      @full_path = File.join(argv[1].to_s.strip)
      usage = <<-EOT

Usage: spout new FOLDER

The FOLDER must be empty or new.

EOT

      if Dir.exists?(@full_path) and (Dir.entries(@full_path) - ['.', '..']).size > 0
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
