require "option_parser"
require "colorize"
require "./options"
require "./dictionaries"
require "./encodings"
require "./utils"
require "./presets"
require "./heuristics"
require "./pipeline"

module Worcestershire
  class CLI
    @options : Options

    def initialize
      @options = Options.new
    end

    def parse
      OptionParser.parse do |parser|
        parser.banner = "Usage: worcestershire [arguments]"

        # Input
        parser.on("-w WORDS", "--words WORDS", "Space-separated words to process") do |words|
          @options.words = words.split
        end

        parser.on("-i FILE", "--input FILE", "Input file (repeatable)") do |file|
          @options.input_files << file
        end

        # Output
        parser.on("-o FILE", "--output FILE", "Output file (default: output.lst)") do |file|
          @options.output_file = file
        end

        parser.on("--format FMT", "Output format: txt, json, hashcat (default: txt)") do |fmt|
          @options.format = fmt
        end

        parser.on("--compress", "Compress output with gzip") do
          @options.compress = true
        end

        parser.on("--force", "Overwrite output without prompting") do
          @options.force = true
        end

        parser.on("--dry-run", "Estimate size only; do not generate") do
          @options.dry_run = true
        end

        parser.on("--quiet", "Suppress all non-essential output") do
          @options.quiet = true
        end

        # Combinations
        parser.on("-c COMBOS", "--combination COMBOS", "Combination types (1-10, space-separated)") do |combos|
          @options.combinations = combos.split.map(&.to_i)
        end

        parser.on("-d DEPTH", "--depth DEPTH", "Word mix depth (2-5, default: 3)") do |depth|
          @options.depth = depth.to_i.clamp(2, 5)
        end

        parser.on("-m MIN", "--min MIN", "Minimum output length") do |min|
          @options.min_length = min.to_i.clamp(0, 49)
        end

        parser.on("-M MAX", "--max MAX", "Maximum output length") do |max|
          @options.max_length = max.to_i.clamp(1, 50)
        end

        parser.on("-e ENC", "--encode ENC", "Encoding/hash algorithm") do |enc|
          validate_encoding(enc)
        end

        # Advanced
        parser.on("--max-combinations N", "Stop after N combinations") do |n|
          @options.max_combinations = n.to_u64
        end

        parser.on("--rules FILE", "Apply JTR-style rule file") do |file|
          @options.rule_file = file
        end

        parser.on("--resume FILE", "Resume from saved state file") do |file|
          @options.resume = file
        end

        parser.on("--log-file FILE", "Write logs to file") do |file|
          @options.log_file = file
        end

        parser.on("--log-level LEVEL", "Log level: debug, info, warn, error (default: info)") do |level|
          @options.log_level = level
        end

        parser.on("--buffer-size BYTES", "Output buffer size (default: 1048576)") do |bytes|
          @options.buffer_size = bytes.to_i
        end

        parser.on("--no-color", "Disable coloured output") do
          @options.no_color = true
        end

        parser.on("--parallel", "Enable multi-threading (requires -Dpreview_mt)") do
          @options.parallel = true
        end

        parser.on("--workers N", "Number of concurrent workers (default: 4)") do |n|
          @options.workers = n.to_i
        end

        parser.on("--cache-size N", "Encoding LRU cache size (default: 1000)") do |n|
          @options.cache_size = n.to_i
        end

        parser.on("--max-memory BYTES", "Abort if heap exceeds N bytes") do |bytes|
          @options.max_memory = bytes.to_u64
        end

        # Custom dictionaries
        parser.on("--homograph-dict FILE", "Custom homograph substitutions file") do |file|
          @options.homograph_dict = file
        end

        parser.on("--leet-dict FILE", "Custom leet substitutions file") do |file|
          @options.leet_dict = file
        end

        parser.on("--salt-dict FILE", "Custom salt dictionary file") do |file|
          @options.salt_dict = file
        end

        parser.on("--affix-dict FILE", "Custom affix dictionary file") do |file|
          @options.affix_dict = file
        end

        # Config
        parser.on("--config FILE", "Load options from a YAML config file") do |file|
          @options.config_file = file
        end

        # New feature flags
        parser.on("--pipeline STEPS", "Chain transforms: comma-separated types (e.g. 2,6,5)") do |steps|
          parsed = steps.split(',').map(&.strip.to_i)
          invalid = parsed.reject { |s| TransformPipeline.valid_step?(s) }
          unless invalid.empty?
            Utils.print_error("Pipeline types #{invalid.join(", ")} are not valid single-word transforms. " \
                              "Valid types: #{TransformPipeline::VALID_STEPS.to_a.sort.join(", ")}.")
            exit 1
          end
          @options.pipeline = parsed
        end

        parser.on("--deduplicate", "Remove duplicate output words using a bloom filter") do
          @options.deduplicate = true
        end

        parser.on("--output-delimiter STR", "Delimiter for Word Mix (type 1) joins (default: none)") do |str|
          @options.output_delimiter = str
        end

        parser.on("--benchmark", "Run a built-in benchmark and report words/sec") do
          @options.benchmark = true
        end

        parser.on("--pattern PATTERN", "Generate words from a typed pattern (e.g. ?w?d?d?d)") do |pat|
          @options.pattern = pat
        end

        # Helpful
        parser.on("-l", "--list", "List combination types and exit") do
          @options.list_combinations = true
        end

        parser.on("--preset NAME", "Apply a named preset") do |name|
          @options.preset = name
        end

        parser.on("--suggest", "Analyse input and suggest combination types") do
          @options.suggest = true
        end

        parser.on("-V", "--verbose", "Verbose output") do
          @options.verbose = true
        end

        parser.on("-N", "--noprogress", "Disable progress bar") do
          @options.no_progress = true
        end

        parser.on("--examples", "Print usage examples and exit") do
          print_examples
          exit 0
        end

        parser.on("--explain COMBOS", "Explain selected combination types") do |combos|
          explain_combinations(combos.split.map(&.to_i))
          exit 0
        end

        parser.on("--interactive", "Run interactive setup wizard") do
          # Wizard is required by worcestershire.cr; instantiate directly.
          Wizard.new.run
          exit 0
        end

        parser.on("-v", "--version", "Print version and exit") do
          puts "Worcestershire v#{VERSION}"
          exit 0
        end

        parser.on("-h", "--help", "Print help and exit") do
          puts parser
          exit 0
        end

        parser.invalid_option do |flag|
          Utils.print_error("#{flag} is not a valid option.")
          puts parser
          exit 1
        end
      end

      @options.load_config! if @options.config_file

      if preset = @options.preset
        @options = Worcestershire.apply_preset(preset, @options)
      end

      handle_list_combinations

      if @options.suggest
        words = load_words_for_suggestion
        suggested = Worcestershire::Heuristics.suggest_combinations(words)
        puts "Suggested combinations: #{suggested.map { |c| "#{c} (#{COMBINATION_TYPES[c]})" }.join(", ")}"
        exit 0
      end

      validate_options unless @options.benchmark || !@options.pattern.nil?
      @options
    end

    private def validate_encoding(enc)
      if ENCODING_TYPES.has_key?(enc)
        @options.encoding = enc
      else
        Utils.print_error("Unknown encoding '#{enc}'")
        puts "Available: #{ENCODING_TYPES.keys.join(", ")}"
        exit 1
      end
    end

    private def load_words_for_suggestion
      words = [] of String
      @options.input_files.each do |file|
        File.each_line(file) { |line| words << line.strip unless line.strip.empty? }
      end
      words.concat(@options.words)
      words.uniq
    end

    private def handle_list_combinations
      if @options.list_combinations
        puts "Combination Types:".colorize(:green).bold
        COMBINATION_TYPES.each do |num, desc|
          puts "  #{num.to_s.rjust(2)}. #{desc}"
        end
        exit 0
      end
    end

    private def validate_options
      if @options.words.empty? && @options.input_files.empty?
        Utils.print_error("No words provided. Use -w or -i.")
        exit 1
      end
    end

    private def print_examples
      puts <<-EXAMPLES
      Examples:
        worcestershire -w password admin -o wordlist.txt
        worcestershire -i words.txt -c 1 2 3 -e base64
        worcestershire -i names.txt -c 6 7 8 --format json --compress
        worcestershire --interactive
        worcestershire --explain 1 3 5
        worcestershire -i base.txt --suggest
        worcestershire -i words.txt --preset password-cracking
        worcestershire --resume state.json --force
        worcestershire -i words.txt --pipeline 2,6,5
        worcestershire -i words.txt --pattern "?w?d?d?d?d"
        worcestershire -i words.txt -c 1 2 3 --deduplicate
        worcestershire -i words.txt -c 1 --output-delimiter "-"
        worcestershire --benchmark
      EXAMPLES
    end

    private def explain_combinations(combos)
      puts "Explanation of selected combination types:".colorize(:green).bold
      combos.each do |c|
        case c
        when  1 then puts "   1. Word Mix: Concatenates permutations of input words up to --depth."
        when  2 then puts "   2. Case Alternate: All case variants (Password, PASSWORD, pAsSWoRd, ...)."
        when  3 then puts "   3. Homograph: Substitutes chars with visual look-alikes (a -> @, 4, α)."
        when  4 then puts "   4. Reverser: Reverses each word (drowssap)."
        when  5 then puts "   5. Saltify: Prepends/appends salt dictionary entries (123password, password!)."
        when  6 then puts "   6. Leet Speak: Applies leet substitutions (e -> 3, s -> 5)."
        when  7 then puts "   7. Separator Insert: Joins word pairs/triples with separators (pass-word)."
        when  8 then puts "   8. Affix: Prepends/appends common affixes (!password, password2024)."
        when  9 then puts "   9. Keyboard Walk: Substitutes each character with adjacent QWERTY keys."
        when 10 then puts "  10. Date Variation: Appends/prepends date strings (password2024, 01012000password)."
        else         puts "  #{c}: Unknown type"
        end
      end
    end
  end
end
