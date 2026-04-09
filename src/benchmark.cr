require "./generator"
require "./cli"

module Worcestershire
  module Benchmark
    WORDS  = ["password", "admin", "letmein", "dragon", "master"]
    COMBOS = [2, 3, 6]
    DEPTH  = 2

    def self.run(base_options : Options)
      puts "Running benchmark...".colorize(:cyan)
      puts "  Input words : #{WORDS.join(", ")}"
      puts "  Combinations: #{COMBOS.join(", ")} (Case Alternate, Homograph, Leet Speak)"
      puts ""

      opts = Options.new
      opts.words = WORDS.dup
      opts.combinations = COMBOS.dup
      opts.depth = DEPTH
      opts.output_file = File.join(Dir.tempdir, "worcestershire_bench_#{Random.rand(1_000_000)}.lst")
      opts.force = true
      opts.quiet = true
      opts.no_progress = true
      opts.no_color = base_options.no_color

      start = Time.instant
      generator = Generator.new(opts, WORDS.dup)
      generator.run
      elapsed = Time.instant - start

      count = begin
        File.read_lines(opts.output_file).size
      rescue
        0
      end
      File.delete(opts.output_file) if File.exists?(opts.output_file)

      wps = elapsed.total_seconds > 0.0 ? (count.to_f / elapsed.total_seconds).round.to_i : 0

      puts "Results:".colorize(:green).bold
      puts "  Words generated : #{count}".colorize(:yellow)
      puts "  Elapsed         : #{elapsed.total_milliseconds.round(2)} ms".colorize(:yellow)
      puts "  Throughput      : #{wps} words/sec".colorize(:yellow)
    end
  end
end
