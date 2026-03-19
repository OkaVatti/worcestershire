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

    it "exits on missing rule file" do
      expect_raises(exit) { RuleEngine.new("nonexistent.txt") }
    end
  end
end
