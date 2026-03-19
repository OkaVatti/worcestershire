require "./cli"
require "./generator"
require "./utils"
require "./wizard"

module Worcestershire
  VERSION = "1.0.0"

  class App
    def run
      if ARGV.empty?
        # No arguments -> launch interactive wizard
        Wizard.new.run
      else
        # Parse CLI arguments
        cli = CLI.new
        options = cli.parse

        # Load words
        words = load_words(options)

        # Run generator
        generator = Generator.new(options, words)
        generator.run
      end
    end

    private def load_words(options : Options) : Array(String)
      words = [] of String

      # Load from multiple input files
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

      # Add words from command line
      words.concat(options.words)

      if words.empty?
        Utils.print_error("No words loaded")
        exit(1)
      end

      unique_words = words.uniq
      Utils.log_verbose("Loaded #{unique_words.size} unique words", options.verbose)
      unique_words
    end
  end
end

# Run the application
Worcestershire::App.new.run
