require "colorize"
require "./dictionaries"
require "./encodings"
require "./utils"
require "./generator"
require "./cli"

module Worcestershire
  class Wizard
    @options : Options

    def initialize
      @options = Options.new
    end

    def run
      puts "\n=== Worcestershire Interactive Setup ===".colorize(:green).bold
      puts "Let's configure your wordlist generation step by step.\n"

      # Step 1: Input words
      input_words
      # Step 2: Combination types
      choose_combinations
      # Step 3: Depth (if word mix selected)
      set_depth if @options.combinations.includes?(1)
      # Step 4: Length filters
      set_length_filters
      # Step 5: Encoding
      choose_encoding
      # Step 6: Output settings
      set_output
      # Step 7: Advanced options (config, rules, etc.)
      advanced_options

      # Summary and confirmation
      print_summary
      if confirm_run
        puts "\nStarting generation...".colorize(:green)
        # Delegate to generator
        words = load_words_interactive
        generator = Generator.new(@options, words)
        generator.run
      else
        puts "Cancelled."
      end
    end

    private def input_words
      puts "\n[1/7] Input words".colorize(:cyan)
      puts "You can provide words manually or from a file."

      loop do
        puts "Enter words separated by spaces, or type 'file <path>' to load from a file:"
        print "> "
        input = gets.to_s.strip
        if input.starts_with?("file ")
          file = input[5..].strip
          if File.exists?(file)
            @options.input_files << file
            puts "Loaded words from #{file}."
            break
          else
            puts "File not found. Try again.".colorize(:red)
          end
        elsif !input.empty?
          @options.words = input.split
          puts "Using words: #{@options.words.join(", ")}"
          break
        else
          puts "Please enter something.".colorize(:red)
        end
      end
    end

    private def choose_combinations
      puts "\n[2/7] Combination types".colorize(:cyan)
      puts "Available combinations:"
      COMBINATION_TYPES.each do |num, desc|
        puts "  #{num}. #{desc}"
      end
      puts "Enter numbers (space-separated) or 'all' for all, 'none' for base words only:"
      print "> "
      input = gets.to_s.strip
      case input.downcase
      when "all"
        @options.combinations = COMBINATION_TYPES.keys
      when "none"
        @options.combinations = [] of Int32
      else
        @options.combinations = input.split.map(&.to_i).select { |i| COMBINATION_TYPES.has_key?(i) }
      end
      if @options.combinations.empty?
        puts "Using base words only (no combinations)."
      else
        puts "Selected: #{@options.combinations.map { |c| COMBINATION_TYPES[c] }.join(", ")}"
      end
    end

    private def set_depth
      puts "\n[Depth for Word Mix]".colorize(:cyan)
      puts "Depth controls how many words are mixed together (2-5). Default is 3."
      print "Enter depth (2-5) [3]: "
      input = gets.to_s.strip
      depth = input.to_i?
      if depth && depth >= 2 && depth <= 5
        @options.depth = depth
      else
        @options.depth = 3
        puts "Using default depth 3."
      end
    end

    private def set_length_filters
      puts "\n[3/7] Length filters".colorize(:cyan)
      print "Minimum word length (0-49) [0]: "
      min = gets.to_s.strip.to_i?
      @options.min_length = min.clamp(0, 49) if min
      print "Maximum word length (1-50) [20]: "
      max = gets.to_s.strip.to_i?
      @options.max_length = max.clamp(1, 50) if max
    end

    private def choose_encoding
      puts "\n[4/7] Encoding / Hashing".colorize(:cyan)
      puts "Available encodings: #{ENCODING_TYPES.keys.join(", ")}"
      puts "Enter one or leave blank for none:"
      print "> "
      enc = gets.to_s.strip
      if ENCODING_TYPES.has_key?(enc)
        @options.encoding = enc
        puts "Will encode with #{enc}."
      elsif !enc.empty?
        puts "Unknown encoding, ignoring.".colorize(:yellow)
      end
    end

    private def set_output
      puts "\n[5/7] Output settings".colorize(:cyan)
      print "Output filename [output.lst]: "
      file = gets.to_s.strip
      @options.output_file = file unless file.empty?
      print "Output format (txt/json) [txt]: "
      fmt = gets.to_s.strip.downcase
      @options.format = fmt if ["txt", "json"].includes?(fmt)
      print "Compress with gzip? (y/n) [n]: "
      compress = gets.to_s.strip.downcase
      @options.compress = true if compress.starts_with?('y')
    end

    private def advanced_options
      puts "\n[6/7] Advanced options".colorize(:cyan)
      print "Configuration file (optional): "
      cfg = gets.to_s.strip
      @options.config_file = cfg if File.exists?(cfg)
      print "Rule file (optional): "
      rule = gets.to_s.strip
      @options.rule_file = rule if File.exists?(rule)
      print "Maximum combinations (optional, e.g., 1000000): "
      maxc = gets.to_s.strip.to_u64?
      @options.max_combinations = maxc if maxc
    end

    private def print_summary
      puts "\n=== Configuration Summary ===".colorize(:green).bold
      puts "Words: #{@options.words.size} manual, #{@options.input_files.size} file(s)"
      puts "Combinations: #{@options.combinations.map { |c| COMBINATION_TYPES[c] }.join(", ")}"
      puts "Depth: #{@options.depth}"
      puts "Length: #{@options.min_length} to #{@options.max_length}"
      puts "Encoding: #{@options.encoding || "none"}"
      puts "Output: #{@options.output_file} (format: #{@options.format}, compress: #{@options.compress})"
      puts "Config: #{@options.config_file || "none"}"
      puts "Rules: #{@options.rule_file || "none"}"
      puts "Max combinations: #{@options.max_combinations || "unlimited"}"
    end

    private def confirm_run
      print "\nProceed with generation? (y/n) [y]: "
      input = gets.to_s.strip.downcase
      !input.starts_with?('n')
    end

    private def load_words_interactive
      words = [] of String
      @options.input_files.each do |file|
        File.each_line(file) { |line| words << line.strip unless line.strip.empty? }
      end
      words.concat(@options.words)
      words.uniq
    end
  end
end
