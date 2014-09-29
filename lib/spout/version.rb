module Spout
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 9
    TINY = 0
    BUILD = "rc" # nil, "pre", "rc", "rc2"

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.')
  end
end
