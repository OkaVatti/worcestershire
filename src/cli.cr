require "option_parser"
require "yaml"
require "./dictionaries"
require "./encodings"
require "./utils"
require "./wizard"
require "./presets"
require "./heuristics"

module Worcestershire
  class Options
    property words : Array(String)
    property input_files : Array(String)
    property output_file : String
    property combinations : Array(Int32)
    property depth : Int32
    property min_length : Int32
    property max_length : Int32
    property encoding : String?
    property verbose : Bool
    property no_progress : Bool
    property list_combinations : Bool
    property format : String
    property compress : Bool
    property config_file : String?
    property max_combinations : UInt64?
    property rule_file : String?
    property resume : String?                # state file to resume from
    property log_file : String?              # log file path
    property log_level : String = "info"     # debug, info, warn, error
    property buffer_size : Int32 = 1_048_576 # 1 MB default
    property no_color : Bool = false         # colorblind/script friendly
    property force : Bool = false            # overwrite output without prompt
    property dry_run : Bool = false          # only estimate, don't generate
    property quiet : Bool = false            # suppress all non‑essential output
    property preset : String?                # preset name
    property suggest : Bool = false          # suggest combinations and exit
    property homograph_dict : String?        # custom homograph file
    property leet_dict : String?             # custom leet file
    property salt_dict : String?             # custom salt file
    property affix_dict : String?            # custom affix file
    property parallel : Bool = false         # use true parallelism (MT)
    property workers : Int32 = 4             # number of concurrent workers
    property cache_size : Int32 = 1000       # encoding cache size
    property max_memory : UInt64?            # max memory in bytes (optional)

    def initialize(
      @words = [] of String,
      @input_files = [] of String,
      @output_file = "output.lst",
      @combinations = [] of Int32,
      @depth = 3,
      @min_length = 0,
      @max_length = 20,
      @encoding = nil,
      @verbose = false,
      @no_progress = false,
      @list_combinations = false,
      @format = "txt",
      @compress = false,
      @config_file = nil,
      @max_combinations = nil,
      @rule_file = nil,
      @resume = nil,
      @log_file = nil,
      @log_level = "info",
      @buffer_size = 1_048_576,
      @no_color = false,
      @force = false,
      @dry_run = false,
      @quiet = false,
      @preset = nil,
      @suggest = false,
      @homograph_dict = nil,
      @leet_dict = nil,
      @salt_dict = nil,
      @affix_dict = nil,
      @parallel = false,
      @workers = 4,
      @cache_size = 1000,
      @max_memory = nil,
    )
    end

    # Load configuration from YAML file (if provided) and merge with CLI
    def load_config!
      return unless config = @config_file
      begin
        yaml = File.open(config) { |f| YAML.parse(f) }
        if h = yaml.as_h?
          @depth = h["depth"]?.try(&.as_i) || @depth
          @min_length = h["min_length"]?.try(&.as_i) || @min_length
          @max_length = h["max_length"]?.try(&.as_i) || @max_length
          @format = h["format"]?.try(&.as_s) || @format
          @compress = h["compress"]?.try(&.as_bool) || @compress
          @max_combinations = h["max_combinations"]?.try(&.as_i.to_u64) || @max_combinations
          @buffer_size = h["buffer_size"]?.try(&.as_i) || @buffer_size
          @workers = h["workers"]?.try(&.as_i) || @workers
          @cache_size = h["cache_size"]?.try(&.as_i) || @cache_size
          @max_memory = h["max_memory"]?.try(&.as_i.to_u64) || @max_memory
          if combos = h["combinations"]?.try(&.as_a)
            @combinations = combos.map(&.as_i) if @combinations.empty?
          end
        end
      rescue e
        Utils.print_error("Failed to load config: #{e.message}")
        exit(1)
      end
    end
  end

  class CLI
    @options : Options

    def initialize
      @options = Options.new
    end

    def parse
      OptionParser.parse do |parser|
        parser.banner = "Usage: worcestershire [arguments]"

        # ===== Input =====
        parser.on("-w WORDS", "--words WORDS", "Space‑separated words to process") do |words|
          @options.words = words.split
        end

        parser.on("-i FILE", "--input FILE", "Input file (can be used multiple times)") do |file|
          @options.input_files << file
        end

        # ===== Output =====
        parser.on("-o FILE", "--output FILE", "Output file (default: output.lst)") do |file|
          @options.output_file = file
        end

        parser.on("--format FMT", "Output format: txt, json, hashcat (default: txt)") do |fmt|
          @options.format = fmt
        end

        parser.on("--compress", "Compress output with gzip") do
          @options.compress = true
        end

        parser.on("--force", "Overwrite output file without prompting") do
          @options.force = true
        end

        parser.on("--dry-run", "Only estimate size, do not generate") do
          @options.dry_run = true
        end

        parser.on("--quiet", "Suppress all non‑essential output") do
          @options.quiet = true
        end

        # ===== Combinations =====
        parser.on("-c COMBOS", "--combination COMBOS", "Combination types (1-8, space‑separated)") do |combos|
          @options.combinations = combos.split.map(&.to_i)
        end

        parser.on("-d DEPTH", "--depth DEPTH", "Word mix depth (2-5, default: 3)") do |depth|
          @options.depth = depth.to_i.clamp(2, 5)
        end

        parser.on("-m MIN", "--min MIN", "Minimum output length (0-49)") do |min|
          @options.min_length = min.to_i.clamp(0, 49)
        end

        parser.on("-M MAX", "--max MAX", "Maximum output length (1-50)") do |max|
          @options.max_length = max.to_i.clamp(1, 50)
        end

        parser.on("-e ENC", "--encode ENC", "Encoding/hash algorithm") do |enc|
          validate_encoding(enc)
        end

        # ===== Advanced =====
        parser.on("--max-combinations N", "Stop after generating N combinations") do |n|
          @options.max_combinations = n.to_u64
        end

        parser.on("--rules FILE", "Apply custom transformation rules") do |file|
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

        parser.on("--no-color", "Disable colored output") do
          @options.no_color = true
        end

        parser.on("--parallel", "Enable multi‑threading (requires -Dpreview_mt)") do
          @options.parallel = true
        end

        parser.on("--workers N", "Number of concurrent workers (default: 4)") do |n|
          @options.workers = n.to_i
        end

        parser.on("--cache-size N", "Encoding cache size (default: 1000)") do |n|
          @options.cache_size = n.to_i
        end

        parser.on("--max-memory BYTES", "Maximum memory usage in bytes (e.g., 1073741824 for 1GB)") do |bytes|
          @options.max_memory = bytes.to_u64
        end

        # ===== Custom dictionaries =====
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

        # ===== Helpful =====
        parser.on("-l", "--list", "List combination types") do
          @options.list_combinations = true
        end

        parser.on("--preset NAME", "Use predefined preset: password-cracking, username-enum, quick-test") do |name|
          @options.preset = name
        end

        parser.on("--suggest", "Analyze input and suggest combinations") do
          @options.suggest = true
        end

        parser.on("-V", "--verbose", "Verbose output") do
          @options.verbose = true
        end

        parser.on("-N", "--noprogress", "Disable progress bar") do
          @options.no_progress = true
        end

        parser.on("--examples", "Show usage examples") do
          print_examples
          exit 0
        end

        parser.on("--explain COMBOS", "Explain combination types") do |combos|
          explain_combinations(combos.split.map(&.to_i))
          exit 0
        end

        parser.on("--interactive", "Run interactive wizard") do
          Wizard.new.run
          exit 0
        end

        parser.on("-v", "--version", "Show version") do
          puts "Worcestershire v#{VERSION}"
          exit 0
        end

        parser.on("-h", "--help", "Show help") do
          puts parser
          exit 0
        end

        parser.invalid_option do |flag|
          Utils.print_error("#{flag} is not a valid option.")
          puts parser
          exit 1
        end
      end

      # Load config if provided
      @options.load_config! if @options.config_file

      # Apply preset if provided
      if preset = @options.preset
        @options = Worcestershire.apply_preset(preset, @options)
      end

      # Handle special actions
      handle_list_combinations
      if @options.suggest
        words = load_words_for_suggestion
        suggested = Worcestershire::Heuristics.suggest_combinations(words)
        puts "Suggested combinations: #{suggested.map { |c| "#{c} (#{COMBINATION_TYPES[c]})" }.join(", ")}"
        exit 0
      end

      validate_options
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
          puts "  #{num}. #{desc}"
        end
        exit 0
      end
    end

    private def validate_options
      if @options.words.empty? && @options.input_files.empty?
        Utils.print_error("No words provided. Use -w or -i")
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
      EXAMPLES
    end

    private def explain_combinations(combos)
      puts "Explanation of selected combination types:".colorize(:green).bold
      combos.each do |c|
        desc = COMBINATION_TYPES[c]?
        if desc
          case c
          when 1 then puts "  1. Word Mix: Combines multiple words (e.g., 'pass' + 'word' = 'password'). Depth controls how many words are mixed."
          when 2 then puts "  2. Case Alternate: Generates all case variations (e.g., 'Password', 'PASSWORD', 'pASSWORD')."
          when 3 then puts "  3. Homograph: Substitutes characters with visually similar ones (e.g., 'a' → '@', '4')."
          when 4 then puts "  4. Reverser: Reverses words (e.g., 'drowssap')."
          when 5 then puts "  5. Saltify: Adds common salts before/after words (e.g., '123password', 'password!')."
          when 6 then puts "  6. Leet Speak: Applies leet substitutions (e.g., 'e' → '3', 's' → '5')."
          when 7 then puts "  7. Separator Insert: Joins words with separators like '-', '_', '.'."
          when 8 then puts "  8. Affix: Adds common prefixes and suffixes (e.g., '!', '?', '2024')."
          else        puts "  #{c}: Unknown type"
          end
        else
          puts "  #{c}: Not a valid combination type"
        end
      end
    end
  end
end
