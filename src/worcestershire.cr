require "./cli"
require "./generator"
require "./utils"
require "./wizard"
require "./benchmark"
require "./pattern"
require "./pipeline"

module Worcestershire
  VERSION = "1.0.0"

  class App
    def run
      if ARGV.empty?
        Wizard.new.run
      else
        cli = CLI.new
        options = cli.parse

        if options.benchmark
          Benchmark.run(options)
          exit 0
        end

        words = load_words(options)
        generator = Generator.new(options, words)
        generator.run
      end
    end

    private def load_words(options : Options) : Array(String)
      words = [] of String

      options.input_files.each do |file|
        begin
          File.each_line(file) do |line|
            line = line.strip
            words << line unless line.empty?
          end
        rescue e : File::NotFoundError
          Utils.print_error("Input file '#{file}' not found")
          exit(1)
        end
      end

      words.concat(options.words)

      # For pattern mode we allow zero loaded words (the pattern may not use ?w)
      if words.empty? && options.pattern.nil?
        Utils.print_error("No words loaded")
        exit(1)
      end

      unique = words.uniq
      Utils.log_verbose("Loaded #{unique.size} unique words", options.verbose)
      unique
    end
  end
end

Worcestershire::App.new.run
