require "./spec_helper"

module Worcestershire
  describe "End-to-end integration" do
    it "generates wordlist with combinations" do
      with_temp_wordlist(["pass", "word"]) do |input|
        with_tempfile("out", ".txt") do |output|
          args = ["-i", input, "-c", "1 2", "-d", "2", "-o", output, "--quiet", "--force"]
          run_cli(args)
          lines = File.read_lines(output)
          lines.should contain("password")
          lines.should contain("PASSWORD")
        end
      end
    end

    it "applies encoding" do
      with_temp_wordlist(["test"]) do |input|
        with_tempfile("out", ".txt") do |output|
          args = ["-i", input, "-e", "base64", "-o", output, "--quiet", "--force"]
          run_cli(args)
          lines = File.read_lines(output)
          lines.should eq([Base64.encode("test")])
        end
      end
    end

    it "respects length filters" do
      with_temp_wordlist(["a", "ab", "abc"]) do |input|
        with_tempfile("out", ".txt") do |output|
          args = ["-i", input, "-m", "2", "-M", "2", "-o", output, "--quiet", "--force"]
          run_cli(args)
          lines = File.read_lines(output)
          lines.should eq(["ab"])
        end
      end
    end

    it "compresses output" do
      with_temp_wordlist(["test"]) do |input|
        with_tempfile("out", ".txt.gz") do |output|
          args = ["-i", input, "--compress", "-o", output, "--quiet", "--force"]
          run_cli(args)
          File.open(output) do |f|
            gz = Compress::Gzip::Reader.new(f)
            gz.gets_to_end.strip.should eq("test")
          end
        end
      end
    end

    it "handles dry-run" do
      with_temp_wordlist(["a", "b"]) do |input|
        with_tempfile("out", ".txt") do |output|
          args = ["-i", input, "-c", "1", "-d", "2", "--dry-run"]
          result = run_cli(args) # run_cli already captures output
          result[:output].should contain("Dry run")
          File.exists?(output).should be_false
        end
      end
    end

    it "resumes from state" do
      with_temp_wordlist(["a", "b", "c"]) do |input|
        with_tempfile("out1", ".txt") do |output1|
          with_tempfile("state", ".json") do |state_file|
            # First run, stop early
            args1 = ["-i", input, "-c", "1", "-d", "2", "-o", output1, "--max-combinations", "2", "--resume", state_file, "--quiet", "--force"]
            run_cli(args1)
            File.read_lines(output1).size.should eq(2)

            # Second run should resume and add remaining
            with_tempfile("out2", ".txt") do |output2|
              args2 = ["-i", input, "-c", "1", "-d", "2", "-o", output2, "--resume", state_file, "--quiet", "--force"]
              run_cli(args2)
              File.read_lines(output2).size.should be > 0
            end
          end
        end
      end
    end
  end
end
