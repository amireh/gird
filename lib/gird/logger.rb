module Gird::Log
  SeverityColors = {
    "DEBUG" => "",
    "INFO" => "green",
    "WARN" => "yellow",
  }

  class << self
    attr_accessor :verbose

    def colorize(str, color, options = {})
      background = options[:background] || options[:bg] || false
      style = options[:style]
      offsets = ["gray","red", "green", "yellow", "blue", "magenta", "cyan","white"]
      styles = ["normal","bold","dark","italic","underline","xx","xx","underline","xx","strikethrough"]
      start = background ? 40 : 30
      color_code = start + (offsets.index(color) || 8)
      style_code = styles.index(style) || 0
      "\e[#{style_code};#{color_code}m#{str}\e[0m"
    end

    def get_or_create_logger
      @@logger ||= Logger.new(STDOUT).tap do |logger|
        original_formatter = Logger::Formatter.new

        logger.progname = 'gird'
        logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        logger.formatter = proc { |severity, datetime, progname, msg|
          if self.verbose
            colorize("gird: [#{severity[0]}] #{msg}\n", SeverityColors[severity])
          end
        }
      end
    end

    def logger
      get_or_create_logger
    end
  end
end

module Gird::Logger
  def logger
    Gird::Log.logger
  end
end