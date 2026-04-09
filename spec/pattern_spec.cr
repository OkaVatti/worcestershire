require "./spec_helper"

module Worcestershire
  describe PatternGenerator do
    it "generates literal patterns" do
      pg = PatternGenerator.new([] of String)
      results = [] of String
      pg.generate("abc") { |w| results << w }
      results.should eq(["abc"])
    end

    it "expands ?d to all digits" do
      pg = PatternGenerator.new([] of String)
      results = [] of String
      pg.generate("?d") { |w| results << w }
      results.sort.should eq(("0".."9").to_a.sort)
    end

    it "expands ?w to input words" do
      pg = PatternGenerator.new(["pass", "admin"])
      results = [] of String
      pg.generate("?w") { |w| results << w }
      results.should contain("pass")
      results.should contain("admin")
    end

    it "combines ?w and ?d" do
      pg = PatternGenerator.new(["x"])
      results = [] of String
      pg.generate("?w?d") { |w| results << w }
      results.should contain("x0")
      results.should contain("x9")
      results.size.should eq(10)
    end

    it "respects the max limit" do
      pg = PatternGenerator.new(["x"], 3_u64)
      results = [] of String
      pg.generate("?w?d?d") { |w| results << w }
      results.size.should eq(3)
    end

    it "treats ?? as a literal ?" do
      pg = PatternGenerator.new([] of String)
      results = [] of String
      pg.generate("??") { |w| results << w }
      results.should eq(["?"])
    end

    it "treats unknown ?X as literal string" do
      pg = PatternGenerator.new([] of String)
      results = [] of String
      pg.generate("?z") { |w| results << w }
      results.should eq(["?z"])
    end
  end
end
