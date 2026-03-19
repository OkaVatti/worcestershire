require "./spec_helper"

module Worcestershire
  describe CLI do
    describe "option parsing" do
      it "parses -w words" do
        result = run_cli(["-w", "hello world", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --words" do
        result = run_cli(["--words", "hello world", "--dry-run"])
        result[:status].should be_true
      end

      it "parses -i file" do
        with_temp_wordlist(["one", "two"]) do |path|
          result = run_cli(["-i", path, "--dry-run"])
          result[:status].should be_true
        end
      end

      it "parses multiple -i" do
        with_temp_wordlist(["a"]) do |path1|
          with_temp_wordlist(["b"]) do |path2|
            result = run_cli(["-i", path1, "-i", path2, "--dry-run"])
            result[:status].should be_true
          end
        end
      end

      it "parses -o output" do
        result = run_cli(["-w", "test", "-o", "out.txt", "--dry-run"])
        result[:status].should be_true
      end

      it "parses -c combinations" do
        result = run_cli(["-w", "test", "-c", "1 2 5", "--dry-run"])
        result[:status].should be_true
      end

      it "parses -d depth" do
        result = run_cli(["-w", "test", "-d", "4", "--dry-run"])
        result[:status].should be_true
      end

      it "parses -m min" do
        result = run_cli(["-w", "test", "-m", "5", "--dry-run"])
        result[:status].should be_true
      end

      it "parses -M max" do
        result = run_cli(["-w", "test", "-M", "30", "--dry-run"])
        result[:status].should be_true
      end

      it "parses -e encoding" do
        result = run_cli(["-w", "test", "-e", "base64", "--dry-run"])
        result[:status].should be_true
      end

      it "exits on unknown encoding" do
        result = run_cli(["-w", "test", "-e", "unknown", "--dry-run"])
        result[:status].should be_false
        result[:error].should contain("Unknown encoding")
      end

      it "parses --format" do
        result = run_cli(["-w", "test", "--format", "json", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --compress" do
        result = run_cli(["-w", "test", "--compress", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --force" do
        result = run_cli(["-w", "test", "--force", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --dry-run" do
        result = run_cli(["-w", "test", "--dry-run"])
        result[:status].should be_true
        result[:output].should contain("Dry run")
      end

      it "parses --quiet" do
        result = run_cli(["-w", "test", "--quiet", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --max-combinations" do
        result = run_cli(["-w", "test", "--max-combinations", "1000", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --rules" do
        with_temp_wordlist(["l"]) do |path|
          result = run_cli(["-w", "test", "--rules", path, "--dry-run"])
          result[:status].should be_true
        end
      end

      it "parses --resume" do
        result = run_cli(["-w", "test", "--resume", "state.json", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --log-file" do
        result = run_cli(["-w", "test", "--log-file", "app.log", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --log-level" do
        result = run_cli(["-w", "test", "--log-level", "debug", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --buffer-size" do
        result = run_cli(["-w", "test", "--buffer-size", "2048", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --no-color" do
        result = run_cli(["-w", "test", "--no-color", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --parallel" do
        result = run_cli(["-w", "test", "--parallel", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --workers" do
        result = run_cli(["-w", "test", "--workers", "8", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --cache-size" do
        result = run_cli(["-w", "test", "--cache-size", "500", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --max-memory" do
        result = run_cli(["-w", "test", "--max-memory", "1073741824", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --homograph-dict" do
        with_temp_wordlist(["a->@,4"]) do |path|
          result = run_cli(["-w", "test", "--homograph-dict", path, "--dry-run"])
          result[:status].should be_true
        end
      end

      it "parses --leet-dict" do
        with_temp_wordlist(["e->3"]) do |path|
          result = run_cli(["-w", "test", "--leet-dict", path, "--dry-run"])
          result[:status].should be_true
        end
      end

      it "parses --salt-dict" do
        with_temp_wordlist(["123"]) do |path|
          result = run_cli(["-w", "test", "--salt-dict", path, "--dry-run"])
          result[:status].should be_true
        end
      end

      it "parses --affix-dict" do
        with_temp_wordlist(["!"]) do |path|
          result = run_cli(["-w", "test", "--affix-dict", path, "--dry-run"])
          result[:status].should be_true
        end
      end

      it "parses -l --list" do
        result = run_cli(["-l"])
        result[:status].should be_true
        result[:output].should contain("Combination Types")
      end

      it "parses --preset" do
        result = run_cli(["-w", "test", "--preset", "quick-test", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --suggest" do
        with_temp_wordlist(["password123"]) do |path|
          result = run_cli(["-i", path, "--suggest"])
          result[:status].should be_true
          result[:output].should contain("Suggested combinations")
        end
      end

      it "parses -V --verbose" do
        result = run_cli(["-w", "test", "-V", "--dry-run"])
        result[:status].should be_true
      end

      it "parses -N --noprogress" do
        result = run_cli(["-w", "test", "-N", "--dry-run"])
        result[:status].should be_true
      end

      it "parses --examples" do
        result = run_cli(["--examples"])
        result[:status].should be_true
        result[:output].should contain("Examples")
      end

      it "parses --explain" do
        result = run_cli(["--explain", "1 2"])
        result[:status].should be_true
        result[:output].should contain("Explanation")
      end

      it "parses --interactive" do
        result = run_cli(["--interactive"])
        result[:status].should be_true
      end

      it "parses -v --version" do
        result = run_cli(["-v"])
        result[:status].should be_true
        result[:output].should contain("Worcestershire v")
      end

      it "parses -h --help" do
        result = run_cli(["-h"])
        result[:status].should be_true
        result[:output].should contain("Usage")
      end

      it "validates that at least words or input files are provided" do
        result = run_cli([] of String)
        result[:status].should be_false
        result[:error].should contain("No words provided")
      end
    end

    describe "config loading" do
      it "loads config from file" do
        with_tempfile("config", ".yml") do |path|
          File.write(path, <<-YAML)
          depth: 4
          min_length: 5
          max_length: 25
          format: json
          compress: true
          max_combinations: 5000
          buffer_size: 2048
          workers: 6
          cache_size: 200
          combinations:
            - 1
            - 3
          YAML

          result = run_cli(["-w", "test", "--config", path, "--dry-run"])
          result[:status].should be_true
        end
      end

      it "CLI overrides config" do
        with_tempfile("config", ".yml") do |path|
          File.write(path, "depth: 2")
          result = run_cli(["-w", "test", "--config", path, "-d", "5", "--dry-run"])
          result[:status].should be_true
        end
      end
    end

    describe "preset application" do
      it "applies quick-test preset" do
        result = run_cli(["-w", "test", "--preset", "quick-test", "--dry-run"])
        result[:status].should be_true
      end
    end
  end
end
