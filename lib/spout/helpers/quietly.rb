# frozen_string_literal: true

module Spout
  module Helpers
    # Silences output for tests
    module Quietly
      # From Rails: http://apidock.com/rails/v3.2.13/Kernel/silence_stream
      def silence_stream(stream)
        old_stream = stream.dup
        stream.reopen(/mswin|mingw/ =~ RbConfig::CONFIG['host_os'] ? 'NUL:' : '/dev/null')
        stream.sync = true
        yield
      ensure
        stream.reopen(old_stream)
      end

      # From Rails: http://apidock.com/rails/v3.2.13/Kernel/quietly
      def quietly
        silence_stream(STDOUT) do
          silence_stream(STDERR) do
            yield
          end
        end
      end
    end
  end
end
