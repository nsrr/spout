# frozen_string_literal: true

module Spout
  module Helpers
    module Color
      CLEAR     = "\e[0m"
      BOLD      = "\e[1m"
      ITALIC    = "\e[3m"
      UNDERLINE = "\e[4m"

      # Colors
      BLACK     = "\e[30m"
      RED       = "\e[31m"
      GREEN     = "\e[32m"
      YELLOW    = "\e[33m"
      BLUE      = "\e[34m"
      MAGENTA   = "\e[35m"
      CYAN      = "\e[36m"
      GREY      = "\e[37m"
      GRAY      = "\e[37m"
      WHITE     = "\e[1m\e[39m"

      BLACK_BG   = "\e[40m"
      RED_BG     = "\e[41m"
      GREEN_BG   = "\e[42m"
      YELLOW_BG  = "\e[43m"
      BLUE_BG    = "\e[44m"
      MAGENTA_BG = "\e[45m"
      CYAN_BG    = "\e[46m"
      WHITE_BG   = "\e[47m"

      def colorize(color, bold: false)
        color = self.class.const_get(color.upcase) if color.is_a?(Symbol)
        bold  = bold ? BOLD : ""
        "#{bold}#{color}#{self}#{CLEAR}"
      end

      def uncolorize
        gsub(/\e\[\d{1,2}m/, "")
      end
    end
  end
end

class String
  include Spout::Helpers::Color
end
