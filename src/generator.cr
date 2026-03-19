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
    @stats : NamedTuple(total_generated: UInt64, filtered: UInt64, start_time: Time)
    @channel : Channel(String)
    @rules_engine : RuleEngine?
    @affixes : Array(String)
    @logger : Logger
    @cache : LRUCache(String, String)
    @pool : WorkerPool?
    @resume_state : ResumeState?
    @mutex : Mutex

    def initialize(@options, @words)
      @stats = {
        total_generated: 0_u64,
        filtered:        0_u64,
        start_time:      Time.utc,
      }
      @channel = Channel(String).new(10_000) # bounded channel
      @affixes = DEFAULT_AFFIXES.dup
      if (rule_file = @options.rule_file)
        @rules_engine = RuleEngine.new(rule_file)
      end

      # Initialize logger
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

      # Initialize cache
      @cache = LRUCache(String, String).new(@options.cache_size)

      # Initialize worker pool if parallel mode requested
      @pool = WorkerPool.new(@options.workers) if @options.parallel

      # Load resume state if provided
      if resume_file = @options.resume
        @resume_state = ResumeState.load(resume_file)
        # Use local variable to avoid nil issues
        if state = @resume_state
          @logger.info "Resuming from state saved at #{state.timestamp}"
        else
          @logger.warn "Resume file not found or invalid, starting fresh"
        end
      end

      @mutex = Mutex.new
    end

    def run
      if @options.dry_run
        estimate = estimate_total_combinations
        puts "Dry run: estimated #{estimate} combinations."
        return
      end

      # Check if output exists and not forced
      if File.exists?(@options.output_file) && !@options.force && !@options.quiet
        print "Output file #{@options.output_file} exists. Overwrite? (y/n) "
        if gets.to_s.strip.downcase != "y"
          puts "Aborted."
          exit 0
        end
      end

      # Start memory monitor if limit set
      if max_mem = @options.max_memory
        spawn monitor_memory(max_mem)
      end

      setup_signal_handler

      if @options.combinations.empty?
        @logger.info("No combinations selected - using base words only")
        process_words(@options.words)
      else
        generate_concurrent
      end
    end

    private def setup_signal_handler
      Signal::INT.trap do
        puts "\nReceived SIGINT. Stopping gracefully...".colorize(:yellow)
        # Capture resume state to avoid nil ambiguity
        if state = @resume_state
          state.save(@options.resume.not_nil!)
          @logger.info "Saved resume state to #{@options.resume}"
        end
        print_summary
        exit 0
      end
    end

    private def generate_concurrent
      total_estimate = estimate_total_combinations
      if (max_comb = @options.max_combinations) && total_estimate > max_comb
        @logger.warn("Estimated combinations (#{total_estimate}) exceeds limit (#{max_comb}). Stopping.")
        exit 0
      end

      # Start producer fibers for each combination type
      @options.combinations.each do |combo_type|
        if @pool
          @pool.not_nil!.schedule { generate_combinations(combo_type) }
        else
          spawn generate_combinations(combo_type)
        end
      end

      # Start consumer – now passing UInt64
      if @pool
        @pool.not_nil!.schedule { consume_results(total_estimate) }
      else
        spawn consume_results(total_estimate)
      end

      # Wait for all producers to finish (they send "__DONE__")
      @options.combinations.size.times do
        select
        when @channel.receive
          # just wait
        end
      end

      # Shutdown pool if used
      @pool.try(&.shutdown)
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
    ensure
      @channel.send("__DONE__")
    end

    # --- Existing combination methods ---

    private def word_mix_combinations
      @logger.debug("Generating word mixes with depth #{@options.depth}")
      (2..@options.depth).each do |current_depth|
        @words.each_permutation(current_depth) do |perm|
          word = perm.join
          send_word(word)
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
      @words.each do |word|
        send_word(word.reverse)
      end
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

    # --- New combination methods ---

    private def leet_combinations
      @logger.debug("Generating leet (1337) substitutions")
      @words.each do |word|
        generate_leet(word).each { |w| send_word(w) }
      end
    end

    private def separator_combinations
      @logger.debug("Generating separator insertions")
      (2..3).each do |current_depth|
        @words.each_permutation(current_depth) do |perm|
          SEPARATORS.each do |sep|
            word = perm.join(sep)
            send_word(word)
          end
        end
      end
    end

    private def affix_combinations
      @logger.debug("Applying prefix/suffix")
      @words.each do |word|
        @affixes.each do |affix|
          send_word(affix + word) # prefix
          send_word(word + affix) # suffix
        end
      end
    end

    # --- Helper methods for generating variations ---

    private def send_word(word : String)
      return unless valid_length?(word)

      # Capture resume state to avoid nil ambiguity
      if state = @resume_state
        if state.position > @stats[:total_generated]
          @mutex.synchronize do
            @stats = @stats.merge({total_generated: @stats[:total_generated] + 1})
          end
          return
        end
      end

      if engine = @rules_engine
        engine.apply(word).each { |w| @channel.send(w) if valid_length?(w) }
      else
        @channel.send(word)
      end

      # Update stats and optionally save resume state
      @mutex.synchronize do
        @stats = @stats.merge({total_generated: @stats[:total_generated] + 1})
        if (state = @resume_state) && @stats[:total_generated] % 10_000 == 0
          state.last_word = word
          state.position = @stats[:total_generated]
          state.save(@options.resume.not_nil!)
          @logger.debug("Saved resume state at position #{@stats[:total_generated]}")
        end
      end
    rescue Channel::ClosedError
      # consumer stopped, exit gracefully
    end

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

    private def generate_homographs(word : String) : Array(String)
      variations = [word]
      word.chars.each_with_index do |char, idx|
        if subs = HOMOGRAPH_DICT[char]?
          current = variations.dup
          subs.each do |sub|
            current.each do |var|
              variations << var.sub(char, sub)
            end
          end
        end
      end
      variations.uniq
    end

    private def generate_leet(word : String) : Array(String)
      variations = [word]
      word.chars.each_with_index do |char, idx|
        if subs = LEET_DICT[char]?
          current = variations.dup
          subs.each do |sub|
            current.each do |var|
              variations << var.sub(char, sub)
            end
          end
        end
      end
      variations.uniq
    end

    # --- Consumer with buffered writing and compression ---

    private def consume_results(total_estimate : UInt64)
      # Convert to Int32 safely for progress bar (clamp to Int32 max)
      ticks_for_progress = total_estimate.clamp(0_u64, Int32::MAX.to_u64).to_i32
      progress = ProgressWrapper.new(ticks_for_progress, !@options.no_progress && !@options.quiet && !@options.verbose)
      progress.init("Generating wordlist...")

      output_io = open_output_io
      buffer = IO::Memory.new
      done_count = 0
      generated = 0_u64

      while done_count < @options.combinations.size
        select
        when result = @channel.receive
          if result == "__DONE__"
            done_count += 1
          else
            # Apply encoding and write to buffer
            encoded = apply_encoding(result)
            case @options.format
            when "json"
              buffer.puts({word: encoded}.to_json)
            when "hashcat"
              # Simple hashcat mask format (can be extended)
              buffer.puts encoded
            else
              buffer.puts encoded
            end
            generated += 1
            @stats = @stats.merge({total_generated: generated})

            # Flush buffer periodically
            if buffer.size > @options.buffer_size
              output_io.write(buffer.to_slice)
              buffer.clear
            end

            progress.tick

            # Check max combinations limit
            if (max_comb = @options.max_combinations) && generated >= max_comb
              @logger.info("Reached maximum combinations limit (#{max_comb}). Stopping.")
              break
            end
          end
        end
      end

      # Flush remaining buffer
      output_io.write(buffer.to_slice) if buffer.size > 0
      output_io.close

      progress.finish
      print_summary
    end

    # --- Processor for base words (no combinations) ---

    private def process_words(words : Array(String))
      total = words.size
      progress = ProgressWrapper.new(total, !@options.no_progress && !@options.quiet && !@options.verbose)
      progress.init("Processing base words...")

      # Use block form for safe IO handling
      open_output_io do |output_io|
        generated = 0_u64
        filtered = 0_u64

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

        @stats = @stats.merge({total_generated: generated, filtered: filtered})
      end

      progress.finish
      print_summary
    end

    # --- Overloaded IO open methods ---

    # Version that returns the IO (caller must close)
    private def open_output_io : IO
      file = File.open(@options.output_file, "w")
      if @options.compress
        Compress::Gzip::Writer.new(file, sync_close: true)
      else
        file
      end
    end

    # Version that yields the IO and ensures it's closed
    private def open_output_io(& : IO ->)
      File.open(@options.output_file, "w") do |file|
        if @options.compress
          gzip_writer = Compress::Gzip::Writer.new(file, sync_close: true)
          begin
            yield gzip_writer
          ensure
            gzip_writer.close
          end
        else
          yield file
        end
      end
    end

    # --- Utility methods ---

    private def valid_length?(word : String) : Bool
      word.size >= @options.min_length && word.size <= @options.max_length
    end

    private def apply_encoding(word : String) : String
      if enc = @options.encoding
        @cache.fetch("#{enc}:#{word}") do
          if processor = ENCODING_TYPES[enc]?
            processor.call(word)
          else
            word
          end
        end
      else
        word
      end
    end

    private def estimate_total_combinations : UInt64
      total = 0_u64
      @options.combinations.each do |combo|
        case combo
        when 1 then total += (@words.size ** (@options.depth - 1)) * 100
        when 2 then total += @words.sum { |w| 2_u64 ** [w.size, 10].min }
        when 3 then total += @words.sum { |w| HOMOGRAPH_DICT.values.sum(&.size) + 1 }
        when 4 then total += @words.size
        when 5 then total += @words.size * SALT_DICT.size * 2
        when 6 then total += @words.sum { |w| LEET_DICT.values.sum(&.size) + 1 }
        when 7 then total += @words.size * (@words.size) * SEPARATORS.size # rough
        when 8 then total += @words.size * @affixes.size * 2
        end
      end
      total = 1_u64 if total == 0
      total
    end

    private def print_summary
      elapsed = Time.utc - @stats[:start_time]
      puts "\n" unless @options.quiet
      puts "=== Summary ===".colorize(:green).bold unless @options.no_color
      puts "Total generated: #{@stats[:total_generated]}".colorize(:yellow) unless @options.no_color
      puts "Filtered (length constraints): #{@stats[:filtered]}".colorize(:yellow) unless @options.no_color
      puts "Time elapsed: #{elapsed.total_seconds.round(2)}s".colorize(:yellow) unless @options.no_color
    end

    private def monitor_memory(limit : UInt64)
      loop do
        sleep 5.seconds
        stats = GC.stats
        if stats.total_bytes > limit
          @logger.error("Memory limit exceeded (#{stats.total_bytes} > #{limit}). Aborting.")
          exit 1
        end
      end
    end
  end
end
