# frozen_string_literal: true

module Spout
  module VERSION #:nodoc:
    MAJOR = 1
    MINOR = 0
    TINY = 0
    BUILD = nil # "pre", "rc", "rc2", nil

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join(".").freeze
  end
end
