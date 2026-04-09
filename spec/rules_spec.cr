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

    it "applies multiple commands within a single rule" do
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

    it "skips lines starting with #" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "# comment\nl")
        engine = RuleEngine.new(path)
        engine.apply("TEST").should eq(["TEST", "test"])
      end
    end

    it "handles rotate-left {" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "{")
        engine = RuleEngine.new(path)
        engine.apply("abcd").should eq(["abcd", "bcda"])
      end
    end

    it "handles rotate-right }" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "}")
        engine = RuleEngine.new(path)
        engine.apply("abcd").should eq(["abcd", "dabc"])
      end
    end

    it "handles delete-first [" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "[")
        engine = RuleEngine.new(path)
        engine.apply("abcd").should eq(["abcd", "bcd"])
      end
    end

    it "handles delete-last ]" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "]")
        engine = RuleEngine.new(path)
        engine.apply("abcd").should eq(["abcd", "abc"])
      end
    end

    it "handles reflect f" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "f")
        engine = RuleEngine.new(path)
        engine.apply("ab").should eq(["ab", "abba"])
      end
    end

    it "handles duplicate-each-char q" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "q")
        engine = RuleEngine.new(path)
        engine.apply("ab").should eq(["ab", "aabb"])
      end
    end

    it "handles pluralise p" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "p")
        engine = RuleEngine.new(path)
        results = engine.apply("word")
        results.should contain("words")
      end
    end

    it "handles pluralise p - already ends in s" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "p")
        engine = RuleEngine.new(path)
        results = engine.apply("pass")
        results.should contain("pass")
        results.should_not contain("passs")
      end
    end

    it "handles toggle-all T" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "T")
        engine = RuleEngine.new(path)
        engine.apply("aBcD").should eq(["aBcD", "AbCd"])
      end
    end

    it "handles toggle-at-position TN" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "T1")
        engine = RuleEngine.new(path)
        engine.apply("abcd").should eq(["abcd", "aBcd"])
      end
    end

    it "handles substitute sXY" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "sae")
        engine = RuleEngine.new(path)
        engine.apply("abac").should eq(["abac", "ebec"])
      end
    end

    it "handles truncate 'N" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "'3")
        engine = RuleEngine.new(path)
        engine.apply("password").should eq(["password", "pas"])
      end
    end

    it "handles delete-at-position DN" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "D0")
        engine = RuleEngine.new(path)
        engine.apply("abcd").should eq(["abcd", "bcd"])
      end
    end

    it "handles insert iNX" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "i1!")
        engine = RuleEngine.new(path)
        engine.apply("abc").should eq(["abc", "a!bc"])
      end
    end

    it "handles overwrite oNX" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "o0X")
        engine = RuleEngine.new(path)
        engine.apply("abc").should eq(["abc", "Xbc"])
      end
    end

    it "handles delete-all @X" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "@a")
        engine = RuleEngine.new(path)
        engine.apply("banana").should eq(["banana", "bnn"])
      end
    end

    it "handles duplicate-first-char zN" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "z3")
        engine = RuleEngine.new(path)
        engine.apply("abc").should eq(["abc", "aaabc"])
      end
    end

    it "handles duplicate-last-char ZN" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "Z2")
        engine = RuleEngine.new(path)
        engine.apply("abc").should eq(["abc", "abccc"])
      end
    end

    it "handles append $ with explicit char" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "$!")
        engine = RuleEngine.new(path)
        engine.apply("pass").should eq(["pass", "pass!"])
      end
    end

    it "handles $ at end of rule as append !" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "u$")
        engine = RuleEngine.new(path)
        engine.apply("pass").should eq(["pass", "PASS!"])
      end
    end

    it "handles prepend ^ with explicit char" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "^!")
        engine = RuleEngine.new(path)
        engine.apply("pass").should eq(["pass", "!pass"])
      end
    end

    it "handles inline comment #" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "u#ignore this")
        engine = RuleEngine.new(path)
        engine.apply("pass").should eq(["pass", "PASS"])
      end
    end

    it "handles inverse-capitalise C" do
      with_tempfile("rules", ".txt") do |path|
        File.write(path, "C")
        engine = RuleEngine.new(path)
        engine.apply("Test").should eq(["Test", "tEST"])
      end
    end

    it "exits with status 1 on a missing rule file" do
      result = run_cli(["-w", "test", "--rules", "nonexistent_rules_file_that_does_not_exist.txt"])
      result[:status].should be_false
      (result[:output] + result[:error]).should contain("nonexistent_rules_file")
    end
  end
end
