module Worcestershire
  enum LogLevel
    Debug
    Info
    Warn
    Error
  end

  class Logger
    @level : LogLevel
    @io : IO
    @mutex = Mutex.new

    def initialize(level : LogLevel = LogLevel::Info, @io : IO = STDOUT)
      @level = level
    end

    def debug(msg) : Nil
      log(LogLevel::Debug, msg)
    end

    def info(msg) : Nil
      log(LogLevel::Info, msg)
    end

    def warn(msg) : Nil
      log(LogLevel::Warn, msg)
    end

    def error(msg) : Nil
      log(LogLevel::Error, msg)
    end

    private def log(level : LogLevel, msg)
      return if level < @level
      @mutex.synchronize do
        @io.puts "#{Time.utc} [#{level}] #{msg}"
        @io.flush
      end
    end
  end
end
