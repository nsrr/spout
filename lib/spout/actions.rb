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
      when '--version', '-v', 'version'
        puts "Spout #{Spout::VERSION::STRING}"
      when 'help', '--help', '-h'
        help
      else
        system "bundle exec rake"
      end
    end

  end
end
