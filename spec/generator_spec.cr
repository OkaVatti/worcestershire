require "./spec_helper"

# Run the generator in-process and return lines written to the output file.
def run_and_read(options : Worcestershire::Options,
                 input_words : Array(String)) : Array(String)
  with_tempfile("output", ".txt") do |out_path|
    options.output_file = out_path
    options.force = true
    options.quiet = true
    options.no_progress = true
    generator = Worcestershire::Generator.new(options, input_words)
    generator.run
    return File.read_lines(out_path)
  end
  [] of String
end

module Worcestershire
  describe Generator do
    # -----------------------------------------------------------------------
    # Combination types 1-8 (existing)
    # -----------------------------------------------------------------------

    describe "combination type 1 — Word Mix" do
      it "joins two words in both orders" do
        opts = Options.new(combinations: [1], depth: 2)
        run_and_read(opts, ["a", "b"]).tap do |lines|
          lines.should contain("ab")
          lines.should contain("ba")
        end
      end

      it "respects --depth" do
        opts = Options.new(combinations: [1], depth: 3)
        lines = run_and_read(opts, ["a", "b", "c"])
        # depth-3 permutation "abc"
        lines.should contain("abc")
      end

      it "emits nothing when word count is less than minimum depth (2)" do
        opts = Options.new(combinations: [1], depth: 2)
        run_and_read(opts, ["solo"]).should eq([] of String)
      end

      it "uses --output-delimiter" do
        opts = Options.new(combinations: [1], depth: 2, output_delimiter: "-")
        lines = run_and_read(opts, ["pass", "word"])
        lines.should contain("pass-word")
        lines.should contain("word-pass")
        lines.should_not contain("password")
      end
    end

    describe "combination type 2 — Case Alternate" do
      it "generates all case variants for short words" do
        opts = Options.new(combinations: [2])
        lines = run_and_read(opts, ["ab"])
        lines.sort.should eq(["ab", "aB", "Ab", "AB"].sort)
      end

      it "generates only three variants for words longer than 10 chars" do
        opts = Options.new(combinations: [2])
        lines = run_and_read(opts, ["abcdefghijk"])
        lines.sort.should eq(["abcdefghijk", "ABCDEFGHIJK", "Abcdefghijk"].sort)
      end
    end

    describe "combination type 3 — Homograph" do
      it "substitutes known characters" do
        opts = Options.new(combinations: [3])
        lines = run_and_read(opts, ["a"])
        lines.should contain("a")
        lines.should contain("@")
        lines.should contain("4")
      end
    end

    describe "combination type 4 — Reverser" do
      it "reverses each word" do
        opts = Options.new(combinations: [4])
        run_and_read(opts, ["abc"]).should eq(["cba"])
      end
    end

    describe "combination type 5 — Saltify" do
      it "prepends and appends salt entries" do
        opts = Options.new(combinations: [5])
        lines = run_and_read(opts, ["pass"])
        lines.should contain("123pass")
        lines.should contain("pass123")
      end
    end

    describe "combination type 6 — Leet Speak" do
      it "applies leet substitutions" do
        opts = Options.new(combinations: [6])
        lines = run_and_read(opts, ["leet"])
        lines.should contain("leet")
        lines.should contain("133t")
      end
    end

    describe "combination type 7 — Separator Insert" do
      it "joins word pairs with separator characters" do
        opts = Options.new(combinations: [7])
        lines = run_and_read(opts, ["a", "b"])
        lines.should contain("a-b")
        lines.should contain("a_b")
        lines.should contain("a.b")
      end
    end

    describe "combination type 8 — Affix" do
      it "prepends and appends default affixes" do
        opts = Options.new(combinations: [8])
        lines = run_and_read(opts, ["word"])
        lines.should contain("!word")
        lines.should contain("word!")
        lines.should contain("123word")
        lines.should contain("word123")
      end
    end

    # -----------------------------------------------------------------------
    # Combination type 9 — Keyboard Walk (new)
    # -----------------------------------------------------------------------

    describe "combination type 9 — Keyboard Walk" do
      it "substitutes characters with adjacent QWERTY keys" do
        opts = Options.new(combinations: [9])
        lines = run_and_read(opts, ["a"])
        # 'a' is adjacent to q, w, s, z
        lines.should contain("q")
        lines.should contain("s")
        lines.should contain("z")
        lines.should contain("w")
      end

      it "preserves case when substituting uppercase characters" do
        opts = Options.new(combinations: [9])
        lines = run_and_read(opts, ["A"])
        lines.should contain("Q")
        lines.should contain("S")
      end

      it "does not raise for words with no adjacent-key characters" do
        # Only certain chars have entries in QWERTY_ADJACENT
        opts = Options.new(combinations: [9])
        expect_raises?(Exception) do
          run_and_read(opts, ["12345"])
        end.should be_nil
      end

      it "produces at least one result per letter in a normal word" do
        opts = Options.new(combinations: [9], max_length: 50)
        lines = run_and_read(opts, ["cat"])
        lines.size.should be > 0
      end
    end

    # -----------------------------------------------------------------------
    # Combination type 10 — Date Variation (new)
    # -----------------------------------------------------------------------

    describe "combination type 10 — Date Variation" do
      it "appends date strings" do
        opts = Options.new(combinations: [10], max_length: 50)
        lines = run_and_read(opts, ["pass"])
        lines.should contain("pass2024")
        lines.should contain("pass2023")
      end

      it "prepends date strings" do
        opts = Options.new(combinations: [10], max_length: 50)
        lines = run_and_read(opts, ["pass"])
        lines.should contain("2024pass")
        lines.should contain("1990pass")
      end

      it "produces results for every date string" do
        opts = Options.new(combinations: [10], max_length: 100)
        lines = run_and_read(opts, ["x"])
        # Should have at least 2 * DATE_STRINGS.size entries
        lines.size.should be >= 2 * DATE_STRINGS.size
      end
    end

    # -----------------------------------------------------------------------
    # Multiple combination types simultaneously
    # -----------------------------------------------------------------------

    describe "multiple combination types" do
      it "runs several types and merges results" do
        opts = Options.new(combinations: [2, 4], max_length: 20)
        lines = run_and_read(opts, ["abc"])
        lines.should contain("ABC") # case alternate
        lines.should contain("cba") # reverser
      end
    end

    # -----------------------------------------------------------------------
    # Pipeline mode (new)
    # -----------------------------------------------------------------------

    describe "pipeline mode" do
      it "chains transforms sequentially" do
        # Step 4 (reverse) then step 2 (case alternate)
        opts = Options.new(pipeline: [4, 2])
        lines = run_and_read(opts, ["ab"])
        # "ab" reversed -> "ba"; case alternate -> "ba", "bA", "Ba", "BA"
        lines.should contain("BA")
        lines.should contain("ba")
      end

      it "produces more results than any single step alone" do
        # reverse alone on ["pass"] = 1 entry
        opts_single = Options.new(combinations: [4])
        single = run_and_read(opts_single, ["pass"])

        # reverse + case alternate should produce more
        opts_pipe = Options.new(pipeline: [4, 2])
        piped = run_and_read(opts_pipe, ["pass"])

        piped.size.should be > single.size
      end

      it "deduplicates intermediates within the pipeline" do
        # Reverse twice returns original; case alternate on original
        opts = Options.new(pipeline: [4, 4, 2])
        lines = run_and_read(opts, ["ab"])
        lines.should contain("ab")
        lines.should contain("AB")
        # "ab" should appear exactly once
        lines.count("ab").should eq(1)
      end

      it "respects max_combinations in pipeline mode" do
        opts = Options.new(pipeline: [2, 5], max_combinations: 3_u64, max_length: 50)
        lines = run_and_read(opts, ["pass"])
        lines.size.should be <= 3
      end

      it "respects length filters in pipeline mode" do
        opts = Options.new(pipeline: [5], min_length: 10, max_length: 12)
        lines = run_and_read(opts, ["pass"])
        lines.each do |line|
          line.size.should be >= 10
          line.size.should be <= 12
        end
      end
    end

    # -----------------------------------------------------------------------
    # Pattern mode (new)
    # -----------------------------------------------------------------------

    describe "pattern mode" do
      it "expands ?w to each input word" do
        opts = Options.new(pattern: "?w")
        lines = run_and_read(opts, ["alpha", "beta"])
        lines.should contain("alpha")
        lines.should contain("beta")
        lines.size.should eq(2)
      end

      it "expands ?d to all ten digits" do
        opts = Options.new(pattern: "?d")
        lines = run_and_read(opts, [] of String)
        lines.sort.should eq(("0".."9").to_a.sort)
      end

      it "expands ?w?d to word + digit combinations" do
        opts = Options.new(pattern: "?w?d")
        lines = run_and_read(opts, ["x"])
        lines.should contain("x0")
        lines.should contain("x9")
        lines.size.should eq(10)
      end

      it "treats ?? as a literal question mark" do
        opts = Options.new(pattern: "??")
        lines = run_and_read(opts, [] of String)
        lines.should eq(["?"])
      end

      it "respects max_combinations in pattern mode" do
        opts = Options.new(pattern: "?w?d?d", max_combinations: 5_u64)
        lines = run_and_read(opts, ["x"])
        lines.size.should be <= 5
      end

      it "respects length filters in pattern mode" do
        # Each result is ?w (1 char) + ?d (1 char) = 2 chars
        opts = Options.new(pattern: "?w?d", min_length: 3, max_length: 50)
        lines = run_and_read(opts, ["x"])
        # "x0".."x9" are all 2 chars, filtered out by min_length 3
        lines.should eq([] of String)
      end
    end

    # -----------------------------------------------------------------------
    # Deduplication (new)
    # -----------------------------------------------------------------------

    describe "deduplication" do
      it "removes duplicate words across combination types" do
        # Case alternate on "a" gives ["a", "A"]
        # Reverser on "a"  gives ["a"]
        # Without dedup, "a" appears twice; with dedup, once.
        opts = Options.new(combinations: [2, 4], deduplicate: true)
        lines = run_and_read(opts, ["a"])
        lines.count("a").should eq(1)
      end

      it "does not drop genuinely distinct words" do
        opts = Options.new(combinations: [2, 4], deduplicate: true)
        lines = run_and_read(opts, ["a"])
        lines.should contain("A") # from case alternate
        lines.should contain("a") # original
      end
    end

    # -----------------------------------------------------------------------
    # Base-word passthrough (no combinations)
    # -----------------------------------------------------------------------

    describe "no combinations selected" do
      it "writes base words unchanged" do
        opts = Options.new
        run_and_read(opts, ["a", "b"]).should eq(["a", "b"])
      end
    end

    # -----------------------------------------------------------------------
    # Encoding
    # -----------------------------------------------------------------------

    describe "encoding" do
      it "applies base64 encoding" do
        opts = Options.new(encoding: "base64")
        run_and_read(opts, ["test"]).should eq([Base64.encode("test")])
      end

      it "applies md5 hashing" do
        opts = Options.new(encoding: "md5")
        run_and_read(opts, ["test"]).should eq([Digest::MD5.hexdigest("test")])
      end

      it "applies sha256 hashing" do
        opts = Options.new(encoding: "sha256")
        run_and_read(opts, ["test"]).should eq([Digest::SHA256.hexdigest("test")])
      end

      it "applies hex encoding" do
        opts = Options.new(encoding: "hex")
        run_and_read(opts, ["ab"]).should eq(["6162"])
      end
    end

    # -----------------------------------------------------------------------
    # Output format
    # -----------------------------------------------------------------------

    describe "output format" do
      it "writes txt format by default" do
        opts = Options.new
        run_and_read(opts, ["hello"]).should eq(["hello"])
      end

      it "writes json format" do
        opts = Options.new(format: "json")
        lines = run_and_read(opts, ["hello"])
        lines.should eq(["{\"word\":\"hello\"}"])
      end

      it "writes hashcat format (same as txt)" do
        opts = Options.new(format: "hashcat")
        run_and_read(opts, ["hello"]).should eq(["hello"])
      end
    end

    # -----------------------------------------------------------------------
    # Length filtering
    # -----------------------------------------------------------------------

    describe "length filtering" do
      it "filters words shorter than min_length" do
        opts = Options.new(min_length: 3)
        run_and_read(opts, ["a", "ab", "abc"]).should eq(["abc"])
      end

      it "filters words longer than max_length" do
        opts = Options.new(max_length: 2)
        run_and_read(opts, ["a", "ab", "abc"]).should eq(["a", "ab"])
      end

      it "keeps words within [min, max] range" do
        opts = Options.new(min_length: 2, max_length: 2)
        run_and_read(opts, ["a", "ab", "abc"]).should eq(["ab"])
      end
    end

    # -----------------------------------------------------------------------
    # Max combinations
    # -----------------------------------------------------------------------

    describe "max_combinations limit" do
      it "stops generating after N entries" do
        opts = Options.new(combinations: [1], depth: 2, max_combinations: 1_u64)
        run_and_read(opts, ["a", "b"]).size.should eq(1)
      end
    end

    # -----------------------------------------------------------------------
    # Dry run
    # -----------------------------------------------------------------------

    describe "dry run" do
      it "prints an estimate and does not write output" do
        opts = Options.new(combinations: [1], depth: 2, dry_run: true)
        output = with_captured_stdout do
          Generator.new(opts, ["a", "b"]).run
        end
        output.should contain("Dry run")
        output.should contain("estimated")
      end
    end

    # -----------------------------------------------------------------------
    # Resume
    # -----------------------------------------------------------------------

    describe "resume support" do
      it "skips words whose position index is below the saved position" do
        state = ResumeState.new(position: 1_u64)
        state_path = ""
        with_tempfile("state", ".json") do |path|
          state.save(path)
          state_path = path

          opts = Options.new(combinations: [4], resume: path)
          lines = run_and_read(opts, ["abc", "def"])
          # position 0 ("cba") skipped; position 1 ("fed") included
          lines.should_not contain("cba")
          lines.should contain("fed")
        end
      end
    end

    # -----------------------------------------------------------------------
    # Custom dictionaries loaded from files
    # -----------------------------------------------------------------------

    describe "custom dictionary loading" do
      it "loads a custom homograph dict" do
        with_tempfile("hg", ".txt") do |path|
          File.write(path, "x->9,y")
          opts = Options.new(combinations: [3], homograph_dict: path)
          lines = run_and_read(opts, ["x"])
          lines.should contain("9")
          lines.should contain("y")
        end
      end

      it "loads a custom leet dict" do
        with_tempfile("leet", ".txt") do |path|
          File.write(path, "x->9")
          opts = Options.new(combinations: [6], leet_dict: path)
          lines = run_and_read(opts, ["x"])
          lines.should contain("9")
        end
      end

      it "loads a custom salt dict" do
        with_tempfile("salt", ".txt") do |path|
          File.write(path, "MYSALT")
          opts = Options.new(combinations: [5], salt_dict: path)
          lines = run_and_read(opts, ["pass"])
          lines.should contain("MYSALTpass")
          lines.should contain("passMYSALT")
        end
      end

      it "loads a custom affix dict" do
        with_tempfile("affix", ".txt") do |path|
          File.write(path, "MYAFFIX")
          opts = Options.new(combinations: [8], affix_dict: path)
          lines = run_and_read(opts, ["word"])
          lines.should contain("MYAFFIXword")
          lines.should contain("wordMYAFFIX")
        end
      end
    end
  end
end
