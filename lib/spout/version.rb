module Spout
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 11
    TINY = 0
    BUILD = 'beta3' # 'pre', 'rc', 'rc2', nil

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.')
  end
end
