require "./spec_helper"

module Worcestershire
  describe Logger do
    it "logs at appropriate level" do
      io = IO::Memory.new
      logger = Logger.new(level: LogLevel::Info, io: io)
      logger.debug("debug")
      logger.info("info")
      logger.warn("warn")
      logger.error("error")
      output = io.to_s
      output.should contain("info")
      output.should contain("warn")
      output.should contain("error")
      output.should_not contain("debug")
    end

    it "writes to file" do
      with_tempfile("log", ".txt") do |path|
        File.open(path, "w") do |f|
          logger = Logger.new(level: LogLevel::Info, io: f)
          logger.info("test")
        end
        File.read(path).should contain("test")
      end
    end
  end
end
