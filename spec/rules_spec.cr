require "./spec_helper"

module Worcestershire
  describe RuleEngine do
    it "loads rules from file" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "l\nu")
        engine = RuleEngine.new(path)
        engine.apply("Test").should eq(["Test", "test", "TEST"])
      end
    end

    it "applies multiple rules in sequence" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "lr")
        engine = RuleEngine.new(path)
        engine.apply("AbC").should eq(["AbC", "cba"])
      end
    end

    it "handles unknown commands gracefully" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "x")
        engine = RuleEngine.new(path)
        engine.apply("test").should eq(["test", "test"])
      end
    end

    it "exits with status 1 and prints an error on a missing rule file" do
      # RuleEngine calls exit(1) on File::NotFoundError.  Crystal has no
      # SystemExit exception, so we verify the behaviour in a subprocess.
      result = run_cli(["-w", "test", "--rules", "nonexistent_rules_file_that_does_not_exist.txt"])
      result[:status].should be_false
      # Utils.print_error writes to STDOUT (colorize output goes to STDOUT).
      (result[:output] + result[:error]).should contain("nonexistent_rules_file")
    end
  end
end
