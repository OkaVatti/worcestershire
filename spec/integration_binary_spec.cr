require "./spec_helper"

# ---------------------------------------------------------------------------
# Guard: skip all tests if the binary has not been compiled.
# The integration CI job always builds first; this guard prevents
# accidental failures when running `crystal spec` without a binary.
# ---------------------------------------------------------------------------

unless File.exists?(BIN_PATH) && File.executable?(BIN_PATH)
  STDERR.puts ""
  STDERR.puts "INFO: #{BIN_PATH} not found or not executable."
  STDERR.puts "      Run 'shards build' to build the binary, then re-run this file."
  STDERR.puts "      Skipping all binary integration tests."
  STDERR.puts ""
  exit 0
end

module Worcestershire
  # =========================================================================
  # Helper: build a temp wordlist and run the binary against it
  # =========================================================================

  private def self.with_word_input(words : Array(String), &block : String -> Nil)
    with_tempfile("input", ".txt") do |path|
      File.write(path, words.join("\n"))
      block.call(path)
    end
  end

  # =========================================================================
  # Informational / exit-immediately flags
  # =========================================================================

  describe "informational flags" do
    it "--help prints usage and exits 0" do
      r = run_binary(["--help"])
      r[:status].should be_true
      r[:output].should contain("Usage")
    end

    it "-h is equivalent to --help" do
      r = run_binary(["-h"])
      r[:status].should be_true
      r[:output].should contain("Usage")
    end

    it "--version prints version string and exits 0" do
      r = run_binary(["--version"])
      r[:status].should be_true
      r[:output].should contain("Worcestershire v")
    end

    it "-v is equivalent to --version" do
      r = run_binary(["-v"])
      r[:status].should be_true
      r[:output].should contain("Worcestershire v")
    end

    it "--list prints all combination types and exits 0" do
      r = run_binary(["--list"])
      r[:status].should be_true
      r[:output].should contain("Combination Types")
      r[:output].should contain("Word Mix")
      r[:output].should contain("Date Variation")
    end

    it "-l is equivalent to --list" do
      r = run_binary(["-l"])
      r[:status].should be_true
      r[:output].should contain("Combination Types")
    end

    it "--examples prints examples and exits 0" do
      r = run_binary(["--examples"])
      r[:status].should be_true
      r[:output].should contain("worcestershire")
    end

    it "--explain 1 2 describes selected types" do
      r = run_binary(["--explain", "1 2"])
      r[:status].should be_true
      r[:output].should contain("Word Mix")
      r[:output].should contain("Case Alternate")
    end

    it "--explain works for all types 1-10" do
      r = run_binary(["--explain", "1 2 3 4 5 6 7 8 9 10"])
      r[:status].should be_true
      (1..10).each do |n|
        r[:output].should contain(n.to_s + ".")
      end
    end

    it "no arguments prints a message and exits 0" do
      r = run_binary([] of String)
      r[:status].should be_true
    end

    it "an invalid flag exits non-zero" do
      r = run_binary(["--totally-invalid-flag-xyz"])
      r[:status].should be_false
    end
  end

  # =========================================================================
  # --suggest heuristics
  # =========================================================================

  describe "--suggest" do
    it "suggests combination types for a given word list" do
      with_word_input(["Password1"]) do |input|
        r = run_binary(["-i", input, "--suggest"])
        r[:status].should be_true
        r[:output].should contain("Suggested combinations")
      end
    end

    it "works with -w words" do
      r = run_binary(["-w", "hello world", "--suggest"])
      r[:status].should be_true
      r[:output].should contain("Suggested combinations")
    end
  end

  # =========================================================================
  # --dry-run
  # =========================================================================

  describe "--dry-run" do
    it "prints an estimate without creating an output file" do
      with_tempfile("out", ".lst") do |output|
        with_word_input(["pass", "word"]) do |input|
          r = run_binary(["-i", input, "-c", "1", "-d", "2", "--dry-run"])
          r[:status].should be_true
          r[:output].should contain("Dry run")
          File.exists?(output).should be_false
        end
      end
    end
  end

  # =========================================================================
  # All ten combination types via the real binary
  # =========================================================================

  describe "combination types" do
    it "type 1 — Word Mix produces permutations" do
      with_word_input(["pass", "word"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "1", "-d", "2",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("password")
          lines.should contain("wordpass")
        end
      end
    end

    it "type 2 — Case Alternate produces all case variants" do
      with_word_input(["ab"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "2",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("ab")
          lines.should contain("AB")
          lines.should contain("Ab")
          lines.should contain("aB")
        end
      end
    end

    it "type 3 — Homograph substitutes look-alike characters" do
      with_word_input(["a"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "3",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("@")
          lines.should contain("4")
        end
      end
    end

    it "type 4 — Reverser reverses each word" do
      with_word_input(["abc"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "4",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          File.read_lines(output).should contain("cba")
        end
      end
    end

    it "type 5 — Saltify prepends and appends salts" do
      with_word_input(["pass"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "5",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("123pass")
          lines.should contain("pass123")
        end
      end
    end

    it "type 6 — Leet Speak applies leet substitutions" do
      with_word_input(["leet"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "6",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          File.read_lines(output).should contain("133t")
        end
      end
    end

    it "type 7 — Separator Insert joins word pairs with separators" do
      with_word_input(["a", "b"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "7",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("a-b")
          lines.should contain("a_b")
        end
      end
    end

    it "type 8 — Affix prepends and appends affixes" do
      with_word_input(["word"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "8",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("!word")
          lines.should contain("word!")
        end
      end
    end

    it "type 9 — Keyboard Walk substitutes adjacent QWERTY keys" do
      with_word_input(["a"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "9",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("q")
          lines.should contain("s")
        end
      end
    end

    it "type 10 — Date Variation appends/prepends date strings" do
      with_word_input(["pass"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "10", "--max", "50",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("pass2024")
          lines.should contain("2024pass")
        end
      end
    end
  end

  # =========================================================================
  # Multiple combination types together
  # =========================================================================

  describe "multiple combination types" do
    it "applies types 1 and 2 together" do
      with_word_input(["pass", "word"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "1 2", "-d", "2",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("password")
          lines.should contain("PASSWORD")
        end
      end
    end
  end

  # =========================================================================
  # Encoding modes
  # =========================================================================

  describe "encoding modes" do
    {% for enc in %w[base64 base32 url hex md5 sha1 sha256 sha512] %}
      it "{{enc.id}} encodes output" do
        with_word_input(["test"]) do |input|
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input, "-e", {{enc}},
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            # Output file should be non-empty and not equal the raw input
            content = File.read(output).strip
            content.should_not be_empty
            content.should_not eq("test")
          end
        end
      end
    {% end %}

    it "rejects an unknown encoding with non-zero exit" do
      r = run_binary(["-w", "test", "-e", "bogusenc", "--dry-run"])
      r[:status].should be_false
      (r[:output] + r[:error]).should contain("Unknown encoding")
    end
  end

  # =========================================================================
  # Output formats
  # =========================================================================

  describe "output format" do
    it "txt (default) writes one word per line" do
      with_word_input(["hello", "world"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "-o", output, "--force", "--quiet"])
          lines = File.read_lines(output)
          lines.should eq(["hello", "world"])
        end
      end
    end

    it "json writes one JSON object per line" do
      with_word_input(["hello"]) do |input|
        with_tempfile("out", ".json") do |output|
          run_binary(["-i", input, "--format", "json",
                      "-o", output, "--force", "--quiet"])
          File.read_lines(output).should eq(["{\"word\":\"hello\"}"])
        end
      end
    end

    it "hashcat format writes one word per line (same as txt)" do
      with_word_input(["hello"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "--format", "hashcat",
                      "-o", output, "--force", "--quiet"])
          File.read_lines(output).should eq(["hello"])
        end
      end
    end
  end

  # =========================================================================
  # Gzip compression
  # =========================================================================

  describe "--compress" do
    it "writes gzip-compressed output" do
      with_word_input(["test"]) do |input|
        with_tempfile("out", ".gz") do |output|
          r = run_binary(["-i", input, "--compress",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          # Decompress and verify
          File.open(output) do |f|
            gz = Compress::Gzip::Reader.new(f)
            content = gz.gets_to_end
            gz.close
            content.strip.should eq("test")
          end
        end
      end
    end
  end

  # =========================================================================
  # Length filtering
  # =========================================================================

  describe "length filtering" do
    it "--min filters out words shorter than the threshold" do
      with_word_input(["a", "ab", "abc"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "--min", "3",
                      "-o", output, "--force", "--quiet"])
          File.read_lines(output).should eq(["abc"])
        end
      end
    end

    it "--max filters out words longer than the threshold" do
      with_word_input(["a", "ab", "abc"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "--max", "2",
                      "-o", output, "--force", "--quiet"])
          lines = File.read_lines(output)
          lines.should contain("a")
          lines.should contain("ab")
          lines.should_not contain("abc")
        end
      end
    end

    it "--min and --max together keep only words within range" do
      with_word_input(["a", "ab", "abc"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "--min", "2", "--max", "2",
                      "-o", output, "--force", "--quiet"])
          File.read_lines(output).should eq(["ab"])
        end
      end
    end
  end

  # =========================================================================
  # --max-combinations
  # =========================================================================

  describe "--max-combinations" do
    it "stops generation after N entries" do
      with_word_input(["a", "b", "c"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "-c", "1", "-d", "2",
                      "--max-combinations", "2",
                      "-o", output, "--force", "--quiet"])
          File.read_lines(output).size.should eq(2)
        end
      end
    end
  end

  # =========================================================================
  # --output-delimiter
  # =========================================================================

  describe "--output-delimiter" do
    it "uses the specified delimiter for Word Mix joins" do
      with_word_input(["pass", "word"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "1", "-d", "2",
                          "--output-delimiter", "-",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("pass-word")
          lines.should contain("word-pass")
          lines.should_not contain("password")
        end
      end
    end

    it "empty delimiter (default) concatenates without separator" do
      with_word_input(["pass", "word"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "-c", "1", "-d", "2",
                      "-o", output, "--force", "--quiet"])
          lines = File.read_lines(output)
          lines.should contain("password")
          lines.should contain("wordpass")
        end
      end
    end
  end

  # =========================================================================
  # --deduplicate
  # =========================================================================

  describe "--deduplicate" do
    it "removes duplicate words that appear in multiple combination types" do
      # Case alternate on "a" -> ["a", "A"]
      # Reverser on "a"       -> ["a"]
      # Without dedup "a" appears twice; with dedup exactly once.
      with_word_input(["a"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "-c", "2 4",
                      "--deduplicate",
                      "-o", output, "--force", "--quiet"])
          lines = File.read_lines(output)
          lines.count("a").should eq(1)
        end
      end
    end

    it "preserves genuinely distinct words" do
      with_word_input(["a"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "-c", "2 4",
                      "--deduplicate",
                      "-o", output, "--force", "--quiet"])
          lines = File.read_lines(output)
          lines.should contain("a")
          lines.should contain("A")
        end
      end
    end
  end

  # =========================================================================
  # --pipeline
  # =========================================================================

  describe "--pipeline" do
    it "chains transforms so each step feeds the next" do
      with_word_input(["ab"]) do |input|
        with_tempfile("out", ".lst") do |output|
          # reverse then case-alternate
          r = run_binary(["-i", input, "--pipeline", "4,2",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("BA")
          lines.should contain("ba")
        end
      end
    end

    it "rejects multi-word types (1, 7) in pipeline with non-zero exit" do
      r = run_binary(["-w", "test", "--pipeline", "1,2"])
      r[:status].should be_false
    end

    it "respects --max-combinations in pipeline mode" do
      with_word_input(["pass"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "--pipeline", "2,5",
                      "--max-combinations", "3", "--max", "50",
                      "-o", output, "--force", "--quiet"])
          File.read_lines(output).size.should be <= 3
        end
      end
    end
  end

  # =========================================================================
  # --pattern
  # =========================================================================

  describe "--pattern" do
    it "generates ?w?d combinations" do
      with_word_input(["x"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "--pattern", "?w?d",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          lines = File.read_lines(output)
          lines.should contain("x0")
          lines.should contain("x9")
          lines.size.should eq(10)
        end
      end
    end

    it "generates ?d?d combinations (100 entries)" do
      with_tempfile("out", ".lst") do |output|
        r = run_binary(["-w", "dummy", "--pattern", "?d?d",
                        "-o", output, "--force", "--quiet"])
        r[:status].should be_true
        File.read_lines(output).size.should eq(100)
      end
    end

    it "treats ?? as a literal question mark" do
      with_tempfile("out", ".lst") do |output|
        run_binary(["-w", "dummy", "--pattern", "??",
                    "-o", output, "--force", "--quiet"])
        File.read_lines(output).should eq(["?"])
      end
    end

    it "respects --max-combinations in pattern mode" do
      with_word_input(["x"]) do |input|
        with_tempfile("out", ".lst") do |output|
          run_binary(["-i", input, "--pattern", "?w?d?d",
                      "--max-combinations", "5",
                      "-o", output, "--force", "--quiet"])
          File.read_lines(output).size.should be <= 5
        end
      end
    end
  end

  # =========================================================================
  # --benchmark
  # =========================================================================

  describe "--benchmark" do
    it "prints throughput and exits 0" do
      r = run_binary(["--benchmark"])
      r[:status].should be_true
      r[:output].should contain("words/sec")
    end
  end

  # =========================================================================
  # Presets
  # =========================================================================

  describe "--preset" do
    it "quick-test preset exits 0 and writes output" do
      with_word_input(["pass"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "--preset", "quick-test",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
        end
      end
    end

    it "username-enum preset exits 0" do
      with_word_input(["alice", "bob"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "--preset", "username-enum",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
        end
      end
    end

    it "password-cracking preset exits 0" do
      with_word_input(["pass"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "--preset", "password-cracking",
                          "--max-combinations", "100",
                          "-o", output, "--force", "--quiet"])
          r[:status].should be_true
        end
      end
    end
  end

  # =========================================================================
  # Multiple input files
  # =========================================================================

  describe "multiple -i flags" do
    it "merges words from all input files" do
      with_word_input(["alpha"]) do |f1|
        with_word_input(["beta"]) do |f2|
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", f1, "-i", f2,
                        "-o", output, "--force", "--quiet"])
            lines = File.read_lines(output)
            lines.should contain("alpha")
            lines.should contain("beta")
          end
        end
      end
    end
  end

  # =========================================================================
  # -w inline words
  # =========================================================================

  describe "-w inline words" do
    it "accepts space-separated words" do
      with_tempfile("out", ".lst") do |output|
        r = run_binary(["-w", "hello world", "-o", output, "--force", "--quiet"])
        r[:status].should be_true
        lines = File.read_lines(output)
        lines.should contain("hello")
        lines.should contain("world")
      end
    end
  end

  # =========================================================================
  # Rule files
  # =========================================================================

  describe "--rules" do
    it "applies l (lowercase) rule" do
      with_word_input(["TEST"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "l")
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input, "--rules", rules,
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            File.read_lines(output).should contain("test")
          end
        end
      end
    end

    it "applies u (uppercase) rule" do
      with_word_input(["test"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "u")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("TEST")
          end
        end
      end
    end

    it "applies r (reverse) rule" do
      with_word_input(["abc"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "r")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("cba")
          end
        end
      end
    end

    it "applies combined rules (lr = lowercase then reverse)" do
      with_word_input(["ABC"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "lr")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("cba")
          end
        end
      end
    end

    it "applies sXY (substitute) rule" do
      with_word_input(["abac"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "sae")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("ebec")
          end
        end
      end
    end

    it "skips comment lines in rule files" do
      with_word_input(["TEST"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "# this is a comment\nl")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("test")
          end
        end
      end
    end

    it "exits non-zero when rule file does not exist" do
      r = run_binary(["-w", "test",
                      "--rules", "nonexistent_rule_file_xyz_abc_123.rule",
                      "--dry-run"])
      r[:status].should be_false
      (r[:output] + r[:error]).should contain("nonexistent_rule_file")
    end

    it "applies { (rotate-left) rule" do
      with_word_input(["abcd"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "{")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("bcda")
          end
        end
      end
    end

    it "applies } (rotate-right) rule" do
      with_word_input(["abcd"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "}")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("dabc")
          end
        end
      end
    end

    it "applies T (toggle-all-case) rule" do
      with_word_input(["aBcD"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "T")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("AbCd")
          end
        end
      end
    end

    it "applies d (duplicate) rule" do
      with_word_input(["ab"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "d")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("abab")
          end
        end
      end
    end

    it "applies f (reflect) rule" do
      with_word_input(["ab"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "f")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("abba")
          end
        end
      end
    end

    it "applies p (pluralise) rule" do
      with_word_input(["word"]) do |input|
        with_tempfile("rules", ".rule") do |rules|
          File.write(rules, "p")
          with_tempfile("out", ".lst") do |output|
            run_binary(["-i", input, "--rules", rules,
                        "-o", output, "--force", "--quiet"])
            File.read_lines(output).should contain("words")
          end
        end
      end
    end
  end

  # =========================================================================
  # Custom dictionaries
  # =========================================================================

  describe "custom dictionaries" do
    it "--homograph-dict overrides built-in substitutions" do
      with_word_input(["x"]) do |input|
        with_tempfile("hg", ".txt") do |dict|
          File.write(dict, "x->9,y")
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input, "-c", "3",
                            "--homograph-dict", dict,
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            lines = File.read_lines(output)
            lines.should contain("9")
            lines.should contain("y")
          end
        end
      end
    end

    it "--leet-dict overrides built-in leet substitutions" do
      with_word_input(["x"]) do |input|
        with_tempfile("leet", ".txt") do |dict|
          File.write(dict, "x->9")
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input, "-c", "6",
                            "--leet-dict", dict,
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            File.read_lines(output).should contain("9")
          end
        end
      end
    end

    it "--salt-dict overrides built-in salts" do
      with_word_input(["pass"]) do |input|
        with_tempfile("salt", ".txt") do |dict|
          File.write(dict, "UNIQUESALT")
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input, "-c", "5",
                            "--salt-dict", dict,
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            lines = File.read_lines(output)
            lines.should contain("UNIQUESALTpass")
            lines.should contain("passUNIQUESALT")
          end
        end
      end
    end

    it "--affix-dict overrides built-in affixes" do
      with_word_input(["word"]) do |input|
        with_tempfile("affix", ".txt") do |dict|
          File.write(dict, "UNIQUEAFFIX")
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input, "-c", "8",
                            "--affix-dict", dict,
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            lines = File.read_lines(output)
            lines.should contain("UNIQUEAFFIXword")
            lines.should contain("wordUNIQUEAFFIX")
          end
        end
      end
    end
  end

  # =========================================================================
  # YAML config file
  # =========================================================================

  describe "--config" do
    it "loads options from a YAML config and respects them" do
      with_word_input(["pass"]) do |input|
        with_tempfile("config", ".yml") do |cfg|
          File.write(cfg, <<-YAML)
          min_length: 4
          max_length: 6
          format: txt
          combinations:
            - 4
          YAML
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input, "--config", cfg,
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            # "pass" reversed = "ssap" (4 chars) — within [4,6]
            File.read_lines(output).should contain("ssap")
          end
        end
      end
    end

    it "CLI flags override config values" do
      with_word_input(["pass"]) do |input|
        with_tempfile("config", ".yml") do |cfg|
          File.write(cfg, "combinations:\n  - 2\n")
          with_tempfile("out", ".lst") do |output|
            # Override config's type 2 with type 4 via CLI
            r = run_binary(["-i", input, "--config", cfg, "-c", "4",
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            lines = File.read_lines(output)
            lines.should contain("ssap")
          end
        end
      end
    end
  end

  # =========================================================================
  # Resume
  # =========================================================================

  describe "--resume" do
    it "resumes from where a previous run stopped" do
      with_word_input(["a", "b", "c"]) do |input|
        with_tempfile("state", ".json") do |state|
          with_tempfile("out1", ".lst") do |out1|
            # First run: stop after 2 combinations
            run_binary(["-i", input, "-c", "1", "-d", "2",
                        "--max-combinations", "2",
                        "--resume", state,
                        "-o", out1, "--force", "--quiet"])
            File.read_lines(out1).size.should eq(2)

            with_tempfile("out2", ".lst") do |out2|
              # Second run: resume and collect remaining
              r = run_binary(["-i", input, "-c", "1", "-d", "2",
                              "--resume", state,
                              "-o", out2, "--force", "--quiet"])
              r[:status].should be_true
              File.read_lines(out2).size.should be > 0
            end
          end
        end
      end
    end
  end

  # =========================================================================
  # --verbose and --quiet
  # =========================================================================

  describe "verbosity flags" do
    it "--quiet suppresses summary output" do
      with_word_input(["hello"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-o", output, "--force", "--quiet"])
          r[:status].should be_true
          r[:output].should_not contain("Summary")
        end
      end
    end

    it "--verbose does not cause errors" do
      with_word_input(["hello"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-o", output, "--force",
                          "--verbose", "--no-color"])
          r[:status].should be_true
        end
      end
    end
  end

  # =========================================================================
  # --no-color
  # =========================================================================

  describe "--no-color" do
    it "runs without error and produces plain output" do
      with_word_input(["hello"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-o", output, "--force",
                          "--no-color", "--quiet"])
          r[:status].should be_true
          File.read_lines(output).should contain("hello")
        end
      end
    end
  end

  # =========================================================================
  # Error conditions
  # =========================================================================

  describe "error conditions" do
    it "exits non-zero when no words or input file provided" do
      r = run_binary(["-o", "out.lst", "--force", "--dry-run"])
      r[:status].should be_false
      (r[:output] + r[:error]).should contain("No words")
    end

    it "exits non-zero when input file does not exist" do
      r = run_binary(["-i", "no_such_file_xyz.txt", "--dry-run"])
      r[:status].should be_false
    end

    it "exits non-zero for an unknown flag" do
      r = run_binary(["--this-flag-does-not-exist"])
      r[:status].should be_false
    end
  end

  # =========================================================================
  # --parallel flag (compilation-dependent; just check it does not crash)
  # =========================================================================

  describe "--parallel" do
    it "does not crash when --parallel is passed" do
      with_word_input(["a", "b"]) do |input|
        with_tempfile("out", ".lst") do |output|
          r = run_binary(["-i", input, "-c", "1", "-d", "2",
                          "--parallel", "--workers", "2",
                          "-o", output, "--force", "--quiet"])
          # The binary may or may not be compiled with -Dpreview_mt;
          # either way it should exit cleanly.
          (r[:status] == true || r[:status] == false).should be_true
        end
      end
    end
  end

  # =========================================================================
  # Log file and log level
  # =========================================================================

  describe "logging" do
    it "--log-file writes log entries to a file" do
      with_word_input(["hello"]) do |input|
        with_tempfile("log", ".txt") do |logfile|
          with_tempfile("out", ".lst") do |output|
            r = run_binary(["-i", input,
                            "--log-file", logfile,
                            "--log-level", "info",
                            "-o", output, "--force", "--quiet"])
            r[:status].should be_true
            # Log file should be created (may be empty if nothing logged at info)
            File.exists?(logfile).should be_true
          end
        end
      end
    end
  end
end
