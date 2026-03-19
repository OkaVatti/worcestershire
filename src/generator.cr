# src/generator.cr
require "channel"
require "compress/gzip"
require "json"
require "./dictionaries"
require "./encodings"
require "./progress"
require "./utils"
require "./rules"
require "./resume"
require "./cache"
require "./worker_pool"
require "./logger"

module Worcestershire
  class Generator
    @options : Options
    @words : Array(String)
    @total_generated : UInt64
    @filtered : UInt64
    @start_time : Time
    @channel : Channel(String)
    # Dedicated channel for signalling that a producer fiber is done.
    @done_channel : Channel(Nil)
    @rules_engine : RuleEngine?
    @affixes : Array(String)
    @logger : Logger
    @cache : LRUCache(String, String)
    @pool : WorkerPool?
    @resume_state : ResumeState?
    @mutex : Mutex

    def initialize(@options, @words)
      @total_generated = 0_u64
      @filtered = 0_u64
      @start_time = Time.utc
      @channel = Channel(String).new(10_000)
      @done_channel = Channel(Nil).new
      @affixes = DEFAULT_AFFIXES.dup
      if (rule_file = @options.rule_file)
        @rules_engine = RuleEngine.new(rule_file)
      end

      log_io = if (log_file = @options.log_file)
                 File.open(log_file, "a")
               else
                 STDOUT
               end

      log_level = case @options.log_level.downcase
                  when "debug" then LogLevel::Debug
                  when "info"  then LogLevel::Info
                  when "warn"  then LogLevel::Warn
                  when "error" then LogLevel::Error
                  else              LogLevel::Info
                  end
      @logger = Logger.new(level: log_level, io: log_io)
      @cache = LRUCache(String, String).new(@options.cache_size)
      @pool = WorkerPool.new(@options.workers) if @options.parallel
      @mutex = Mutex.new

      if resume_file = @options.resume
        @resume_state = ResumeState.load(resume_file)
        if state = @resume_state
          @logger.info("Resuming from state saved at #{state.timestamp}")
        else
          @logger.warn("Resume file not found or invalid, starting fresh")
        end
      end
    end

    def run
      if @options.dry_run
        estimate = estimate_total_combinations
        puts "Dry run: estimated #{estimate} combinations."
        return
      end

      if File.exists?(@options.output_file) && !@options.force && !@options.quiet
        print "Output file #{@options.output_file} exists. Overwrite? (y/n) "
        if gets.to_s.strip.downcase != "y"
          puts "Aborted."
          exit 0
        end
      end

      if max_mem = @options.max_memory
        spawn { monitor_memory(max_mem) }
      end

      setup_signal_handler

      if @options.combinations.empty?
        @logger.info("No combinations selected - using base words only")
        process_words(@words)
      else
        generate_concurrent
      end
    end

    private def setup_signal_handler
      Signal::INT.trap do
        puts "\nReceived SIGINT. Stopping gracefully...".colorize(:yellow)
        if (resume_path = @options.resume) && (state = @resume_state)
          state.save(resume_path)
          @logger.info("Saved resume state to #{resume_path}")
        end
        print_summary
        exit 0
      end
    end

    private def generate_concurrent
      total_estimate = estimate_total_combinations

      # Launch one producer fiber per combination type.
      @options.combinations.each do |combo_type|
        if pool = @pool
          pool.schedule { produce(combo_type) }
        else
          spawn { produce(combo_type) }
        end
      end

      # Launch the consumer fiber.
      spawn { consume_results(total_estimate) }

      # Wait for all producers to signal completion via @done_channel.
      @options.combinations.size.times { @done_channel.receive }

      # All producers are done; close the word channel so the consumer can drain
      # any remaining items and then exit its loop.
      @channel.close

      # Shutdown pool if used.
      @pool.try(&.shutdown)
    end

    # Wrapper that signals the done channel after each producer finishes.
    private def produce(combo_type : Int32)
      generate_combinations(combo_type)
    ensure
      @done_channel.send(nil)
    end

    private def generate_combinations(combo_type : Int32)
      case combo_type
      when 1 then word_mix_combinations
      when 2 then case_alternate_combinations
      when 3 then homograph_combinations
      when 4 then reverse_combinations
      when 5 then saltify_combinations
      when 6 then leet_combinations
      when 7 then separator_combinations
      when 8 then affix_combinations
      else
        @logger.debug("Unknown combination type: #{combo_type}")
      end
    end

    private def word_mix_combinations
      @logger.debug("Generating word mixes with depth #{@options.depth}")
      (2..@options.depth).each do |current_depth|
        next if @words.size < current_depth
        @words.each_permutation(current_depth) do |perm|
          send_word(perm.join)
        end
      end
    end

    private def case_alternate_combinations
      @logger.debug("Generating case alternations")
      @words.each do |word|
        if word.size <= 10
          generate_case_variations(word).each { |w| send_word(w) }
        else
          send_word(word.upcase)
          send_word(word.downcase)
          send_word(word.capitalize)
        end
      end
    end

    private def homograph_combinations
      @logger.debug("Generating homograph substitutions")
      @words.each do |word|
        generate_homographs(word).each { |w| send_word(w) }
      end
    end

    private def reverse_combinations
      @logger.debug("Generating reversed words")
      @words.each { |word| send_word(word.reverse) }
    end

    private def saltify_combinations
      @logger.debug("Applying salt dictionary")
      @words.each do |word|
        SALT_DICT.each do |salt|
          send_word(salt + word)
          send_word(word + salt)
        end
      end
    end

    private def leet_combinations
      @logger.debug("Generating leet (1337) substitutions")
      @words.each do |word|
        generate_leet(word).each { |w| send_word(w) }
      end
    end

    private def separator_combinations
      @logger.debug("Generating separator insertions")
      (2..3).each do |current_depth|
        next if @words.size < current_depth
        @words.each_permutation(current_depth) do |perm|
          SEPARATORS.each do |sep|
            send_word(perm.join(sep))
          end
        end
      end
    end

    private def affix_combinations
      @logger.debug("Applying prefix/suffix")
      @words.each do |word|
        @affixes.each do |affix|
          send_word(affix + word)
          send_word(word + affix)
        end
      end
    end

    # --- Helper: send a word through the pipeline ---

    private def send_word(word : String)
      return unless valid_length?(word)

      # Resume: skip words whose position index is strictly less than the
      # saved position (i.e. they were already generated in a prior run).
      @mutex.synchronize do
        if (state = @resume_state) && @total_generated < state.position
          @total_generated += 1
          return
        end
      end

      begin
        if engine = @rules_engine
          engine.apply(word).each do |w|
            @channel.send(w) if valid_length?(w)
          end
        else
          @channel.send(word)
        end
      rescue Channel::ClosedError
        return
      end

      @mutex.synchronize do
        @total_generated += 1
        if (resume_path = @options.resume) && (state = @resume_state) && @total_generated % 10_000 == 0
          state.last_word = word
          state.position = @total_generated
          state.save(resume_path)
          @logger.debug("Saved resume state at position #{@total_generated}")
        end
      end
    end

    # --- Variation generators ---

    private def generate_case_variations(word : String) : Array(String)
      variations = [] of String
      (0...2**word.size).each do |mask|
        variant = word.chars.map_with_index do |c, i|
          mask.bit(i) == 1 ? c.upcase : c.downcase
        end.join
        variations << variant
      end
      variations.uniq
    end

    # Generates homograph substitutions positionally: for each character that
    # has substitutions, produce new variants by replacing that single position
    # across all existing variants.
    private def generate_homographs(word : String) : Array(String)
      variants = [word]
      word.chars.each_with_index do |char, idx|
        next unless subs = HOMOGRAPH_DICT[char]?
        new_variants = [] of String
        subs.each do |sub|
          variants.each do |var|
            chars = var.chars
            chars[idx] = sub[0] # sub is a String; take first char-equivalent
            new_variants << chars.join
          end
        end
        variants.concat(new_variants)
      end
      variants.uniq
    end

    private def generate_leet(word : String) : Array(String)
      variants = [word]
      word.chars.each_with_index do |char, idx|
        next unless subs = LEET_DICT[char]?
        new_variants = [] of String
        subs.each do |sub|
          variants.each do |var|
            chars = var.chars
            chars[idx] = sub[0]
            new_variants << chars.join
          end
        end
        variants.concat(new_variants)
      end
      variants.uniq
    end

    # --- Consumer ---

    private def consume_results(total_estimate : UInt64)
      ticks_for_progress = total_estimate.clamp(0_u64, Int32::MAX.to_u64).to_i32
      progress = ProgressWrapper.new(ticks_for_progress, !@options.no_progress && !@options.quiet && !@options.verbose)
      progress.init("Generating wordlist...")

      generated = 0_u64

      open_output_io do |output_io|
        # Drain the channel until it is closed and empty.
        while result = @channel.receive?
          encoded = apply_encoding(result)
          case @options.format
          when "json"
            output_io.puts({word: encoded}.to_json)
          when "hashcat"
            output_io.puts encoded
          else
            output_io.puts encoded
          end
          generated += 1
          progress.tick

          if (max_comb = @options.max_combinations) && generated >= max_comb
            @logger.info("Reached maximum combinations limit (#{max_comb}). Stopping.")
            break
          end
        end
      end

      @mutex.synchronize { @total_generated = generated }
      progress.finish
      print_summary
    end

    # --- Base-word processor (no combinations selected) ---

    private def process_words(words : Array(String))
      progress = ProgressWrapper.new(words.size, !@options.no_progress && !@options.quiet && !@options.verbose)
      progress.init("Processing base words...")

      generated = 0_u64
      filtered = 0_u64

      open_output_io do |output_io|
        words.each do |word|
          if valid_length?(word)
            encoded = apply_encoding(word)
            case @options.format
            when "json"
              output_io.puts({word: encoded}.to_json)
            when "hashcat"
              output_io.puts encoded
            else
              output_io.puts encoded
            end
            generated += 1
          else
            filtered += 1
          end
          progress.tick
        end
      end

      @total_generated = generated
      @filtered = filtered
      progress.finish
      print_summary
    end

    # Block form: yields the IO and ensures it is closed regardless of errors.
    private def open_output_io(& : IO ->)
      File.open(@options.output_file, "w") do |file|
        if @options.compress
          Compress::Gzip::Writer.open(file, sync_close: true) do |gz|
            yield gz
          end
        else
          yield file
        end
      end
    end

    # --- Utilities ---

    private def valid_length?(word : String) : Bool
      word.size >= @options.min_length && word.size <= @options.max_length
    end

    private def apply_encoding(word : String) : String
      if enc = @options.encoding
        @cache.fetch("#{enc}:#{word}") do
          ENCODING_TYPES[enc]?.try(&.call(word)) || word
        end
      else
        word
      end
    end

    private def estimate_total_combinations : UInt64
      total = 0_u64
      @options.combinations.each do |combo|
        case combo
        when 1 then total += (@words.size ** (@options.depth - 1)).to_u64 * 100
        when 2 then total += @words.sum(0_u64) { |w| 2_u64 ** [w.size, 10].min }
        when 3 then total += @words.sum(0_u64) { |w| (HOMOGRAPH_DICT.values.sum(&.size) + 1).to_u64 }
        when 4 then total += @words.size.to_u64
        when 5 then total += @words.size.to_u64 * SALT_DICT.size.to_u64 * 2_u64
        when 6 then total += @words.sum(0_u64) { |w| (LEET_DICT.values.sum(&.size) + 1).to_u64 }
        when 7 then total += @words.size.to_u64 * @words.size.to_u64 * SEPARATORS.size.to_u64
        when 8 then total += @words.size.to_u64 * @affixes.size.to_u64 * 2_u64
        end
      end
      total == 0_u64 ? 1_u64 : total
    end

    private def print_summary
      elapsed = Time.utc - @start_time
      puts "" unless @options.quiet
      if @options.no_color
        puts "=== Summary ==="
        puts "Total generated: #{@total_generated}"
        puts "Filtered (length constraints): #{@filtered}"
        puts "Time elapsed: #{elapsed.total_seconds.round(2)}s"
      else
        puts "=== Summary ===".colorize(:green).bold
        puts "Total generated: #{@total_generated}".colorize(:yellow)
        puts "Filtered (length constraints): #{@filtered}".colorize(:yellow)
        puts "Time elapsed: #{elapsed.total_seconds.round(2)}s".colorize(:yellow)
      end
    end

    private def monitor_memory(limit : UInt64)
      loop do
        sleep 5.seconds
        # GC::Stats#heap_size is the correct field in Crystal 1.19.1.
        used = GC.stats.heap_size
        if used > limit
          @logger.error("Memory limit exceeded (#{used} > #{limit}). Aborting.")
          exit 1
        end
      end
    end
  end
end
