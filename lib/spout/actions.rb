module Spout
  module Actions

    def self.help
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

    def self.interpret(argv)
      case argv.first
      when '--version', '-v', 'version'
        puts "Spout #{Spout::VERSION::STRING}"
        # exit(0)
      when 'help', '--help', '-h'
        help
        exit(0)
      else
        require 'spout/test_helpers'
      end
    end

  end
end
