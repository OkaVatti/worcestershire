require "colorize"

module Worcestershire
  # Utility functions
  module Utils
    extend self

    def log_verbose(message : String, verbose : Bool)
      puts "[VERBOSE] #{message}".colorize(:cyan) if verbose
    end

    def print_error(message : String)
      puts "Error: #{message}".colorize(:red)
    end

    def print_success(message : String)
      puts message.colorize(:green)
    end

    def print_warning(message : String)
      puts message.colorize(:yellow)
    end

    def print_summary(stats : NamedTuple(total_generated: UInt64, filtered: UInt64, start_time: Time), verbose : Bool)
      elapsed = Time.utc - stats[:start_time]
      puts "\n" unless verbose

      puts "=== Summary ===".colorize(:green).bold
      puts "Total generated: #{stats[:total_generated]}".colorize(:yellow)
      puts "Filtered (length constraints): #{stats[:filtered]}".colorize(:yellow)
      puts "Time elapsed: #{elapsed.total_seconds.round(2)}s".colorize(:yellow)
    end
  end
end
