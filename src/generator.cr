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
require "./transforms"
require "./bloom_filter"
require "./pipeline"
require "./pattern"

module Worcestershire
  class Generator
    @options : Options
    @words : Array(String)
    @total_generated : UInt64
    @filtered : UInt64
    @start_time : Time
    @channel : Channel(String)
    @done_channel : Channel(Nil)
    @rules_engine : RuleEngine?
    @logger : Logger
    @cache : LRUCache(String, String)
    @pool : WorkerPool?
    @resume_state : ResumeState?
    @mutex : Mutex
    # Custom dictionaries (loaded from files or defaulting to constants)
    @homograph_dict : Hash(Char, Array(String))
    @leet_dict : Hash(Char, Array(String))
    @salt_dict : Array(String)
    @affixes : Array(String)
    @date_strings : Array(String)
    # Optional features
    @dedup_filter : BloomFilter?
    @output_delimiter : String

    def initialize(@options, @words)
      @total_generated = 0_u64
      @filtered = 0_u64
      @start_time = Time.utc
      @channel = Channel(String).new(10_000)
      @done_channel = Channel(Nil).new
      @output_delimiter = @options.output_delimiter
      @mutex = Mutex.new

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

      @dedup_filter = BloomFilter.new if @options.deduplicate

      @homograph_dict = load_subst_dict(@options.homograph_dict) || HOMOGRAPH_DICT
      @leet_dict = load_subst_dict(@options.leet_dict) || LEET_DICT
      @salt_dict = load_line_list(@options.salt_dict) || SALT_DICT.dup
      @affixes = load_line_list(@options.affix_dict) || DEFAULT_AFFIXES.dup
      @date_strings = DATE_STRINGS.dup

      if rule_file = @options.rule_file
        @rules_engine = RuleEngine.new(rule_file)
      end

      if resume_file = @options.resume
        @resume_state = ResumeState.load(resume_file)
        if state = @resume_state
          @logger.info("Resuming from state saved at #{state.timestamp}")
        else
          @logger.warn("Resume file not found or invalid; starting fresh")
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

      if pattern = @options.pattern
        run_pattern_mode(pattern)
      elsif pipeline_steps = @options.pipeline
        run_pipeline_mode(pipeline_steps)
      elsif @options.combinations.empty?
        @logger.info("No combinations selected; writing base words only")
        process_words(@words)
      else
        generate_concurrent
      end
    end

    # -------------------------------------------------------------------------
    # Pipeline mode
    # -------------------------------------------------------------------------

    private def run_pipeline_mode(steps : Array(Int32))
      invalid = steps.reject { |s| TransformPipeline.valid_step?(s) }
      unless invalid.empty?
        @logger.warn("Pipeline step(s) #{invalid.join(", ")} require multiple words and will be skipped")
      end
      valid_steps = steps.select { |s| TransformPipeline.valid_step?(s) }

      pipeline = TransformPipeline.new(valid_steps,
        @homograph_dict, @leet_dict,
        @salt_dict, @affixes, @date_strings)
      generated = 0_u64
      max_comb = @options.max_combinations

      open_output_io do |io|
        pipeline.run(@words) do |word|
          break if max_comb && generated >= max_comb
          next unless valid_length?(word)
          if f = @dedup_filter
            next unless f.insert_new?(word)
          end
          write_word(io, apply_encoding(word))
          generated += 1
        end
      end

      @total_generated = generated
      print_summary unless @options.quiet
    end

    # -------------------------------------------------------------------------
    # Pattern mode
    # -------------------------------------------------------------------------

    private def run_pattern_mode(pattern : String)
      pg = PatternGenerator.new(@words, @options.max_combinations)
      generated = 0_u64

      open_output_io do |io|
        pg.generate(pattern) do |word|
          next unless valid_length?(word)
          if f = @dedup_filter
            next unless f.insert_new?(word)
          end
          write_word(io, apply_encoding(word))
          generated += 1
        end
      end

      @total_generated = generated
      print_summary unless @options.quiet
    end

    # -------------------------------------------------------------------------
    # Combination mode (concurrent)
    # -------------------------------------------------------------------------

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

      @options.combinations.each do |combo_type|
        if pool = @pool
          pool.schedule { produce(combo_type) }
        else
          spawn { produce(combo_type) }
        end
      end

      spawn { consume_results(total_estimate) }

      @options.combinations.size.times { @done_channel.receive }
      @channel.close
      @pool.try(&.shutdown)
    end

    private def produce(combo_type : Int32)
      generate_combinations(combo_type)
    ensure
      @done_channel.send(nil)
    end

    private def generate_combinations(combo_type : Int32)
      case combo_type
      when  1 then word_mix_combinations
      when  2 then case_alternate_combinations
      when  3 then homograph_combinations
      when  4 then reverse_combinations
      when  5 then saltify_combinations
      when  6 then leet_combinations
      when  7 then separator_combinations
      when  8 then affix_combinations
      when  9 then keyboard_walk_combinations
      when 10 then date_variation_combinations
      else
        @logger.debug("Unknown combination type: #{combo_type}")
      end
    end

    private def word_mix_combinations
      @logger.debug("Generating word mix (depth #{@options.depth}, delimiter: #{@output_delimiter.inspect})")
      (2..@options.depth).each do |d|
        next if @words.size < d
        @words.each_permutation(d) do |perm|
          send_word(perm.join(@output_delimiter))
        end
      end
    end

    private def case_alternate_combinations
      @logger.debug("Generating case alternations")
      @words.each do |word|
        Transforms.case_variants(word).each { |w| send_word(w) }
      end
    end

    private def homograph_combinations
      @logger.debug("Generating homograph substitutions")
      @words.each do |word|
        Transforms.homograph_variants(word, @homograph_dict).each { |w| send_word(w) }
      end
    end

    private def reverse_combinations
      @logger.debug("Generating reversed words")
      @words.each { |word| send_word(Transforms.reverse_variant(word)) }
    end

    private def saltify_combinations
      @logger.debug("Applying salt dictionary")
      @words.each do |word|
        Transforms.saltify_variants(word, @salt_dict).each { |w| send_word(w) }
      end
    end

    private def leet_combinations
      @logger.debug("Generating leet substitutions")
      @words.each do |word|
        Transforms.leet_variants(word, @leet_dict).each { |w| send_word(w) }
      end
    end

    private def separator_combinations
      @logger.debug("Generating separator insertions")
      (2..3).each do |d|
        next if @words.size < d
        @words.each_permutation(d) do |perm|
          SEPARATORS.each do |sep|
            send_word(perm.join(sep))
          end
        end
      end
    end

    private def affix_combinations
      @logger.debug("Applying affixes")
      @words.each do |word|
        Transforms.affix_variants(word, @affixes).each { |w| send_word(w) }
      end
    end

    private def keyboard_walk_combinations
      @logger.debug("Generating keyboard-walk variants")
      @words.each do |word|
        Transforms.keyboard_variants(word).each { |w| send_word(w) }
      end
    end

    private def date_variation_combinations
      @logger.debug("Generating date variation variants")
      @words.each do |word|
        Transforms.date_variants(word, @date_strings).each { |w| send_word(w) }
      end
    end

    # -------------------------------------------------------------------------
    # Word dispatch
    # -------------------------------------------------------------------------

    private def send_word(word : String)
      return unless valid_length?(word)

      if f = @dedup_filter
        return unless f.insert_new?(word)
      end

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
        if (resume_path = @options.resume) &&
           (state = @resume_state) &&
           @total_generated % 10_000 == 0
          state.last_word = word
          state.position = @total_generated
          state.save(resume_path)
          @logger.debug("Saved resume state at position #{@total_generated}")
        end
      end
    end

    # -------------------------------------------------------------------------
    # Consumer
    # -------------------------------------------------------------------------

    private def consume_results(total_estimate : UInt64)
      ticks = total_estimate.clamp(0_u64, Int32::MAX.to_u64).to_i32
      progress = ProgressWrapper.new(ticks, !@options.no_progress && !@options.quiet && !@options.verbose)
      progress.init("Generating wordlist...")

      generated = 0_u64

      open_output_io do |io|
        while result = @channel.receive?
          write_word(io, apply_encoding(result))
          generated += 1
          progress.tick

          if (max_comb = @options.max_combinations) && generated >= max_comb
            @logger.info("Reached max-combinations limit (#{max_comb}). Stopping.")
            break
          end
        end
      end

      @mutex.synchronize { @total_generated = generated }
      progress.finish
      print_summary
    end

    # -------------------------------------------------------------------------
    # Base-word processor (no combinations)
    # -------------------------------------------------------------------------

    private def process_words(words : Array(String))
      progress = ProgressWrapper.new(words.size, !@options.no_progress && !@options.quiet && !@options.verbose)
      progress.init("Processing base words...")

      generated = 0_u64
      filtered = 0_u64

      open_output_io do |io|
        words.each do |word|
          if valid_length?(word)
            write_word(io, apply_encoding(word))
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

    # -------------------------------------------------------------------------
    # Output helpers
    # -------------------------------------------------------------------------

    private def write_word(io : IO, word : String)
      case @options.format
      when "json"
        io.puts({word: word}.to_json)
      else
        io.puts word
      end
    end

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

    # -------------------------------------------------------------------------
    # Utilities
    # -------------------------------------------------------------------------

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
        when  1 then total += (@words.size ** (@options.depth - 1)).to_u64 * 100
        when  2 then total += @words.sum(0_u64) { |w| 2_u64 ** [w.size, 10].min }
        when  3 then total += @words.sum(0_u64) { |w| (HOMOGRAPH_DICT.values.sum(&.size) + 1).to_u64 }
        when  4 then total += @words.size.to_u64
        when  5 then total += @words.size.to_u64 * @salt_dict.size.to_u64 * 2_u64
        when  6 then total += @words.sum(0_u64) { |w| (LEET_DICT.values.sum(&.size) + 1).to_u64 }
        when  7 then total += @words.size.to_u64 * @words.size.to_u64 * SEPARATORS.size.to_u64
        when  8 then total += @words.size.to_u64 * @affixes.size.to_u64 * 2_u64
        when  9 then total += @words.sum(0_u64) { |w| w.size.to_u64 * 4_u64 }
        when 10 then total += @words.size.to_u64 * @date_strings.size.to_u64 * 2_u64
        end
      end
      total == 0_u64 ? 1_u64 : total
    end

    private def print_summary
      elapsed = Time.utc - @start_time
      puts "" unless @options.quiet
      if @options.no_color
        puts "=== Summary ==="
        puts "Total generated            : #{@total_generated}"
        puts "Filtered (length/dedup)    : #{@filtered}"
        puts "Time elapsed               : #{elapsed.total_seconds.round(2)}s"
      else
        puts "=== Summary ===".colorize(:green).bold
        puts "Total generated            : #{@total_generated}".colorize(:yellow)
        puts "Filtered (length/dedup)    : #{@filtered}".colorize(:yellow)
        puts "Time elapsed               : #{elapsed.total_seconds.round(2)}s".colorize(:yellow)
      end
    end

    private def monitor_memory(limit : UInt64)
      loop do
        sleep 5.seconds
        used = GC.stats.heap_size
        if used > limit
          @logger.error("Memory limit exceeded (#{used} > #{limit}). Aborting.")
          exit 1
        end
      end
    end

    # -------------------------------------------------------------------------
    # Custom dictionary loaders
    # -------------------------------------------------------------------------

    # Parses a substitution dict file in the format:
    #   a->@,4,α
    #   e->3,€
    # Returns nil if *path* is nil; raises a logged warning on any error.
    private def load_subst_dict(path : String?) : Hash(Char, Array(String))?
      return nil unless path
      dict = {} of Char => Array(String)
      File.each_line(path) do |line|
        line = line.strip
        next if line.empty? || line.starts_with?('#')
        if m = line.match(/^(.)\s*->\s*(.+)$/)
          char = m[1][0]
          subs = m[2].split(',').map(&.strip).reject(&.empty?)
          dict[char] = subs unless subs.empty?
        end
      end
      dict
    rescue e
      @logger.warn("Could not load substitution dictionary #{path}: #{e.message}")
      nil
    end

    # Parses a simple one-entry-per-line list file.
    # Returns nil if *path* is nil.
    private def load_line_list(path : String?) : Array(String)?
      return nil unless path
      File.read_lines(path).map(&.strip).reject(&.empty?)
    rescue e
      @logger.warn("Could not load list file #{path}: #{e.message}")
      nil
    end
  end
end
