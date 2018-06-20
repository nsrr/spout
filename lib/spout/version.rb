# frozen_string_literal: true

module Spout
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 13
    TINY = 0
    BUILD = "beta2" # "pre", "rc", "rc2", nil

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join(".").freeze
  end
end
