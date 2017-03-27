# frozen_string_literal: true

require 'colorize'
require 'spout/helpers/json_request'

module Spout
  module Commands
    # Command to check if there is an updated version of the gem available.
    class Update
      class << self
        def start(*args)
          new(*args).start
        end
      end

      def initialize(argv)
      end

      def start
        (json, _status) = Spout::Helpers::JsonRequest.get('https://rubygems.org/api/v1/gems/spout.json')
        if json
          if json['version'] == Spout::VERSION::STRING
            puts 'The spout gem is ' + 'up-to-date'.colorize(:green) + '!'
          else
            puts
            puts "A newer version (v#{json['version']}) is available! Type the following command to update:"
            puts
            puts '  gem install spout --no-document'.colorize(:white)
            puts
          end
        else
          puts 'Unable to connect to RubyGems.org. Please try again later.'
        end
      end
    end
  end
end
