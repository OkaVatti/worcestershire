require "./spec_helper"

# cli_spec.cr tests CLI parsing behaviour via the compiled binary.
# The binary must be built before running this file:
#   shards build
#
# If the binary is absent the whole file is skipped gracefully.

unless File.exists?(BIN_PATH) && File.executable?(BIN_PATH)
  STDERR.puts "INFO: #{BIN_PATH} not found — skipping cli_spec. Run 'shards build' first."
  exit 0
end

module Worcestershire
  describe CLI do
    describe "option parsing" do
      # ---------------------------------------------------------------
      # Input
      # ---------------------------------------------------------------

      it "parses -w words" do
        run_binary(["-w", "hello world", "--dry-run"])[:status].should be_true
      end

      it "parses --words" do
        run_binary(["--words", "hello world", "--dry-run"])[:status].should be_true
      end

      it "parses -i file" do
        with_temp_wordlist(["one", "two"]) do |path|
          run_binary(["-i", path, "--dry-run"])[:status].should be_true
        end
      end

      it "parses multiple -i flags" do
        with_temp_wordlist(["a"]) do |p1|
          with_temp_wordlist(["b"]) do |p2|
            run_binary(["-i", p1, "-i", p2, "--dry-run"])[:status].should be_true
          end
        end
      end

      # ---------------------------------------------------------------
      # Output
      # ---------------------------------------------------------------

      it "parses -o output" do
        run_binary(["-w", "test", "-o", "out.txt", "--dry-run"])[:status].should be_true
      end

      it "parses --format txt" do
        run_binary(["-w", "test", "--format", "txt", "--dry-run"])[:status].should be_true
      end

      it "parses --format json" do
        run_binary(["-w", "test", "--format", "json", "--dry-run"])[:status].should be_true
      end

      it "parses --format hashcat" do
        run_binary(["-w", "test", "--format", "hashcat", "--dry-run"])[:status].should be_true
      end

      it "parses --compress" do
        run_binary(["-w", "test", "--compress", "--dry-run"])[:status].should be_true
      end

      it "parses --force" do
        run_binary(["-w", "test", "--force", "--dry-run"])[:status].should be_true
      end

      it "parses --dry-run and prints an estimate" do
        r = run_binary(["-w", "test", "--dry-run"])
        r[:status].should be_true
        r[:output].should contain("Dry run")
      end

      it "parses --quiet" do
        run_binary(["-w", "test", "--quiet", "--dry-run"])[:status].should be_true
      end

      # ---------------------------------------------------------------
      # Combinations
      # ---------------------------------------------------------------

      it "parses -c combinations" do
        run_binary(["-w", "test", "-c", "1 2 5", "--dry-run"])[:status].should be_true
      end

      it "parses -d depth" do
        run_binary(["-w", "test", "-d", "4", "--dry-run"])[:status].should be_true
      end

      it "parses -m min" do
        run_binary(["-w", "test", "-m", "5", "--dry-run"])[:status].should be_true
      end

      it "parses -M max" do
        run_binary(["-w", "test", "-M", "30", "--dry-run"])[:status].should be_true
      end

      # ---------------------------------------------------------------
      # Encoding
      # ---------------------------------------------------------------

      it "parses -e base64" do
        run_binary(["-w", "test", "-e", "base64", "--dry-run"])[:status].should be_true
      end

      it "parses -e sha256" do
        run_binary(["-w", "test", "-e", "sha256", "--dry-run"])[:status].should be_true
      end

      it "exits non-zero for unknown encoding" do
        r = run_binary(["-w", "test", "-e", "bogus", "--dry-run"])
        r[:status].should be_false
        (r[:output] + r[:error]).should contain("Unknown encoding")
      end

      # ---------------------------------------------------------------
      # Advanced
      # ---------------------------------------------------------------

      it "parses --max-combinations" do
        run_binary(["-w", "test", "--max-combinations", "1000", "--dry-run"])[:status].should be_true
      end

      it "parses --rules with an existing file" do
        with_temp_wordlist(["l"]) do |path|
          run_binary(["-w", "test", "--rules", path, "--dry-run"])[:status].should be_true
        end
      end

      it "parses --resume" do
        run_binary(["-w", "test", "--resume", "state.json", "--dry-run"])[:status].should be_true
      end

      it "parses --log-level debug" do
        run_binary(["-w", "test", "--log-level", "debug", "--dry-run"])[:status].should be_true
      end

      it "parses --buffer-size" do
        run_binary(["-w", "test", "--buffer-size", "2048", "--dry-run"])[:status].should be_true
      end

      it "parses --no-color" do
        run_binary(["-w", "test", "--no-color", "--dry-run"])[:status].should be_true
      end

      it "parses --parallel" do
        run_binary(["-w", "test", "--parallel", "--dry-run"])[:status].should be_true
      end

      it "parses --workers" do
        run_binary(["-w", "test", "--workers", "8", "--dry-run"])[:status].should be_true
      end

      it "parses --cache-size" do
        run_binary(["-w", "test", "--cache-size", "500", "--dry-run"])[:status].should be_true
      end

      it "parses --max-memory" do
        run_binary(["-w", "test", "--max-memory", "1073741824", "--dry-run"])[:status].should be_true
      end

      # ---------------------------------------------------------------
      # Custom dictionaries
      # ---------------------------------------------------------------

      it "parses --homograph-dict" do
        with_temp_wordlist(["a->@,4"]) do |path|
          run_binary(["-w", "test", "--homograph-dict", path, "--dry-run"])[:status].should be_true
        end
      end

      it "parses --leet-dict" do
        with_temp_wordlist(["e->3"]) do |path|
          run_binary(["-w", "test", "--leet-dict", path, "--dry-run"])[:status].should be_true
        end
      end

      it "parses --salt-dict" do
        with_temp_wordlist(["123"]) do |path|
          run_binary(["-w", "test", "--salt-dict", path, "--dry-run"])[:status].should be_true
        end
      end

      it "parses --affix-dict" do
        with_temp_wordlist(["!"]) do |path|
          run_binary(["-w", "test", "--affix-dict", path, "--dry-run"])[:status].should be_true
        end
      end

      # ---------------------------------------------------------------
      # Config
      # ---------------------------------------------------------------

      it "parses --config" do
        with_tempfile("config", ".yml") do |path|
          File.write(path, "depth: 2\n")
          run_binary(["-w", "test", "--config", path, "--dry-run"])[:status].should be_true
        end
      end

      # ---------------------------------------------------------------
      # New feature flags
      # ---------------------------------------------------------------

      it "parses --pipeline with valid steps" do
        run_binary(["-w", "test", "--pipeline", "2,6,5", "--dry-run"])[:status].should be_true
      end

      it "rejects --pipeline with multi-word types" do
        run_binary(["-w", "test", "--pipeline", "1,2"])[:status].should be_false
      end

      it "parses --deduplicate" do
        run_binary(["-w", "test", "--deduplicate", "--dry-run"])[:status].should be_true
      end

      it "parses --output-delimiter" do
        run_binary(["-w", "test", "--output-delimiter", "-", "--dry-run"])[:status].should be_true
      end

      it "parses --benchmark" do
        r = run_binary(["--benchmark"])
        r[:status].should be_true
        r[:output].should contain("words/sec")
      end

      it "parses --pattern" do
        run_binary(["-w", "test", "--pattern", "?w?d", "--dry-run"])[:status].should be_true
      end

      # ---------------------------------------------------------------
      # Informational
      # ---------------------------------------------------------------

      it "parses -l --list" do
        r = run_binary(["-l"])
        r[:status].should be_true
        r[:output].should contain("Combination Types")
      end

      it "parses --preset quick-test" do
        run_binary(["-w", "test", "--preset", "quick-test", "--dry-run"])[:status].should be_true
      end

      it "parses --suggest" do
        with_temp_wordlist(["password123"]) do |path|
          r = run_binary(["-i", path, "--suggest"])
          r[:status].should be_true
          r[:output].should contain("Suggested combinations")
        end
      end

      it "parses -V --verbose" do
        run_binary(["-w", "test", "-V", "--dry-run"])[:status].should be_true
      end

      it "parses -N --noprogress" do
        run_binary(["-w", "test", "-N", "--dry-run"])[:status].should be_true
      end

      it "parses --examples" do
        r = run_binary(["--examples"])
        r[:status].should be_true
        r[:output].should contain("worcestershire")
      end

      it "parses --explain 1 2 3" do
        r = run_binary(["--explain", "1 2 3"])
        r[:status].should be_true
        r[:output].should contain("Word Mix")
        r[:output].should contain("Case Alternate")
        r[:output].should contain("Homograph")
      end

      it "parses -v --version" do
        r = run_binary(["-v"])
        r[:status].should be_true
        r[:output].should contain("Worcestershire v")
      end

      it "parses -h --help" do
        r = run_binary(["-h"])
        r[:status].should be_true
        r[:output].should contain("Usage")
      end

      # ---------------------------------------------------------------
      # Validation
      # ---------------------------------------------------------------

      it "exits non-zero when neither -w nor -i is provided" do
        r = run_binary(["--dry-run"])
        r[:status].should be_false
        (r[:output] + r[:error]).should contain("No words")
      end
    end

    describe "config file loading" do
      it "reads all supported keys from a YAML file" do
        with_tempfile("config", ".yml") do |path|
          File.write(path, <<-YAML)
          depth: 4
          min_length: 5
          max_length: 25
          format: json
          compress: true
          max_combinations: 5000
          buffer_size: 2048
          workers: 2
          cache_size: 200
          combinations:
            - 1
            - 3
          YAML
          r = run_binary(["-w", "test", "--config", path, "--dry-run"])
          r[:status].should be_true
        end
      end

      it "CLI flag overrides config value" do
        with_tempfile("config", ".yml") do |path|
          File.write(path, "depth: 2\n")
          r = run_binary(["-w", "test", "--config", path, "-d", "5", "--dry-run"])
          r[:status].should be_true
        end
      end

      it "supports pipeline key in config" do
        with_tempfile("config", ".yml") do |path|
          File.write(path, "pipeline:\n  - 4\n  - 2\n")
          with_temp_wordlist(["ab"]) do |words|
            with_tempfile("out", ".lst") do |output|
              r = run_binary(["-i", words, "--config", path,
                              "-o", output, "--force", "--quiet"])
              r[:status].should be_true
            end
          end
        end
      end
    end

    describe "preset application" do
      it "applies quick-test preset correctly" do
        run_binary(["-w", "test", "--preset", "quick-test", "--dry-run"])[:status].should be_true
      end

      it "applies username-enum preset" do
        run_binary(["-w", "alice", "--preset", "username-enum", "--dry-run"])[:status].should be_true
      end

      it "CLI combination type overrides preset" do
        r = run_binary(["-w", "test", "--preset", "quick-test",
                        "-c", "4", "--dry-run"])
        r[:status].should be_true
      end
    end
  end
end
