# frozen_string_literal: true

module Spout
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 14
    TINY = 1
    BUILD = "pre" # "pre", "rc", "rc2", nil

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join(".").freeze
  end
end
