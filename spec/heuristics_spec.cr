require "./spec_helper"

module Worcestershire
  describe Heuristics do
    describe "suggest_combinations" do
      it "returns empty array for empty word list" do
        Heuristics.suggest_combinations([] of String).should eq([] of Int32)
      end

      it "suggests leet (6) and saltify (5) when words contain digits" do
        result = Heuristics.suggest_combinations(["pass1"])
        result.should contain(6)
        result.should contain(5)
      end

      it "does not suggest leet/saltify for digit-free words" do
        result = Heuristics.suggest_combinations(["alpha"])
        result.should_not contain(6)
        result.should_not contain(5)
      end

      it "suggests case alternate (2) for mixed-case words" do
        result = Heuristics.suggest_combinations(["Password"])
        result.should contain(2)
      end

      it "does not suggest case alternate for all-lowercase words" do
        result = Heuristics.suggest_combinations(["password"])
        result.should_not contain(2)
      end

      it "suggests word mix (1) and separator (7) when two or more words given" do
        result = Heuristics.suggest_combinations(["foo", "bar"])
        result.should contain(1)
        result.should contain(7)
      end

      it "does not suggest word mix / separator for a single word" do
        result = Heuristics.suggest_combinations(["foo"])
        result.should_not contain(1)
        result.should_not contain(7)
      end

      it "suggests reverser (4) for long words (> 8 chars)" do
        result = Heuristics.suggest_combinations(["superlongword"])
        result.should contain(4)
      end

      it "suggests keyboard walk (9) for words with ASCII letters" do
        result = Heuristics.suggest_combinations(["abc"])
        result.should contain(9)
      end

      it "suggests homograph (3) and affix (8) for pure-alpha words" do
        result = Heuristics.suggest_combinations(["alpha"])
        result.should contain(3)
        result.should contain(8)
      end

      it "always includes homograph (3), reverser (4), and affix (8) as fallbacks" do
        result = Heuristics.suggest_combinations(["x"])
        result.should contain(3)
        result.should contain(4)
        result.should contain(8)
      end

      it "suggests date variation (10) for short average-length word sets" do
        result = Heuristics.suggest_combinations(["ab", "cd"])
        result.should contain(10)
      end

      it "returns sorted, deduplicated suggestions" do
        result = Heuristics.suggest_combinations(["Password1", "admin2"])
        result.should eq(result.uniq.sort)
      end

      it "handles a single-character word without raising" do
        expect_raises?(Exception) do
          Heuristics.suggest_combinations(["a"])
        end.should be_nil
      end
    end
  end
end
