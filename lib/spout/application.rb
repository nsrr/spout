module Spout
  class Application
    attr_accessor :version

    def initialize
      @version = '1.0.0'
    end

    def load_tasks
      require "spout/tasks"
    end
  end
end
