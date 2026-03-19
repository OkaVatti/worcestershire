require "./spec_helper"

# Helper to run generator and return output lines
def run_and_read(options : Worcestershire::Options, input_words : Array(String)) : Array(String)
  with_tempfile("output", ".txt") do |out_path|
    options.output_file = out_path
    options.force = true
    options.quiet = true
    generator = Worcestershire::Generator.new(options, input_words)
    generator.run
    File.read_lines(out_path)
  end
end

module Worcestershire
  describe Generator do
    describe "combination methods" do
      it "generates word mix combinations" do
        options = Options.new(combinations: [1], depth: 2)
        input = ["a", "b"]
        output_lines = run_and_read(options, input)
        output_lines.should contain("ab")
        output_lines.should contain("ba")
      end

      it "generates case alternate combinations (short words)" do
        options = Options.new(combinations: [2])
        input = ["ab"]
        output_lines = run_and_read(options, input)
        output_lines.sort.should eq(["ab", "aB", "Ab", "AB"].sort)
      end

      it "generates case alternate combinations (long words, only common)" do
        options = Options.new(combinations: [2])
        input = ["abcdefghijk"]
        output_lines = run_and_read(options, input)
        output_lines.sort.should eq(["ABCDEFGHIJK", "abcdefghijk", "Abcdefghijk"].sort)
      end

      it "generates homograph combinations" do
        options = Options.new(combinations: [3])
        input = ["a"]
        output_lines = run_and_read(options, input)
        output_lines.should contain("a")
        output_lines.should contain("@")
        output_lines.should contain("4")
      end

      it "generates reverse combinations" do
        options = Options.new(combinations: [4])
        input = ["abc"]
        output_lines = run_and_read(options, input)
        output_lines.should eq(["cba"])
      end

      it "generates saltify combinations" do
        options = Options.new(combinations: [5])
        input = ["pass"]
        output_lines = run_and_read(options, input)
        output_lines.should contain("123pass")
        output_lines.should contain("pass123")
      end

      it "generates leet combinations" do
        options = Options.new(combinations: [6])
        input = ["leet"]
        output_lines = run_and_read(options, input)
        output_lines.should contain("leet")
        output_lines.should contain("133t")
      end

      it "generates separator combinations" do
        options = Options.new(combinations: [7])
        input = ["a", "b"]
        output_lines = run_and_read(options, input)
        output_lines.should contain("a-b")
        output_lines.should contain("a_b")
      end

      it "generates affix combinations" do
        options = Options.new(combinations: [8])
        input = ["word"]
        output_lines = run_and_read(options, input)
        output_lines.should contain("!word")
        output_lines.should contain("word!")
      end
    end

    describe "length filtering" do
      it "filters by min and max length" do
        options = Options.new(min_length: 2, max_length: 2)
        input = ["a", "ab", "abc"]
        output_lines = run_and_read(options, input)
        output_lines.should eq(["ab"])
      end
    end

    describe "encoding" do
      it "applies base64 encoding" do
        options = Options.new(encoding: "base64")
        input = ["test"]
        output_lines = run_and_read(options, input)
        output_lines.should eq([Base64.encode("test")])
      end

      it "applies md5 hashing" do
        options = Options.new(encoding: "md5")
        input = ["test"]
        output_lines = run_and_read(options, input)
        output_lines.should eq([Digest::MD5.hexdigest("test")])
      end
    end

    describe "process_words (no combinations)" do
      it "writes base words to file" do
        options = Options.new
        input = ["a", "b"]
        output_lines = run_and_read(options, input)
        output_lines.should eq(["a", "b"])
      end
    end

    describe "dry-run" do
      it "estimates combinations without generating" do
        options = Options.new(combinations: [1], depth: 2, dry_run: true)
        input = ["a", "b"]
        output = with_captured_stdout do
          generator = Generator.new(options, input)
          generator.run
        end
        output.should contain("Dry run: estimated")
      end
    end

    describe "resume" do
      it "skips already generated words" do
        # Create a resume state with position 1
        state = ResumeState.new(position: 1_u64)
        state_path = with_tempfile("state", ".json") do |path|
          File.write(path, state.to_json)
          path
        end

        options = Options.new(combinations: [4], resume: state_path) # reverse
        input = ["abc", "def"]                                       # reverse will generate "cba", "fed"
        output_lines = run_and_read(options, input)
        output_lines.should eq(["fed"])
      end
    end

    describe "max combinations limit" do
      it "stops when limit reached" do
        options = Options.new(combinations: [1], depth: 2, max_combinations: 1_u64)
        input = ["a", "b"]
        output_lines = run_and_read(options, input)
        output_lines.size.should eq(1)
      end
    end
  end
end
