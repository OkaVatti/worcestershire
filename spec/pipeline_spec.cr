require "./spec_helper"

module Worcestershire
  describe TransformPipeline do
    it "returns original words when steps are empty" do
      pipeline = TransformPipeline.new([] of Int32)
      results = [] of String
      pipeline.run(["pass"]) { |w| results << w }
      results.should eq(["pass"])
    end

    it "applies a single step" do
      pipeline = TransformPipeline.new([4]) # Reverser
      results = [] of String
      pipeline.run(["abc"]) { |w| results << w }
      results.should contain("cba")
    end

    it "chains two steps" do
      # Step 4 (reverse) then step 2 (case alternate)
      pipeline = TransformPipeline.new([4, 2])
      results = [] of String
      pipeline.run(["ab"]) { |w| results << w }
      # "ab" reversed -> "ba"; case alternate -> "ba", "bA", "Ba", "BA"
      results.should contain("ba")
      results.should contain("BA")
    end

    it "chains three steps and deduplicates intermediates" do
      pipeline = TransformPipeline.new([4, 4, 2]) # reverse twice -> original, then case
      results = [] of String
      pipeline.run(["ab"]) { |w| results << w }
      results.should contain("ab")
      results.should contain("AB")
    end

    it "valid_step? accepts single-word transform types" do
      TransformPipeline::VALID_STEPS.each do |s|
        TransformPipeline.valid_step?(s).should be_true
      end
    end

    it "valid_step? rejects multi-word types 1 and 7" do
      TransformPipeline.valid_step?(1).should be_false
      TransformPipeline.valid_step?(7).should be_false
    end

    it "accepts custom leet dict" do
      custom_leet = {'a' => ["4"]}
      pipeline = TransformPipeline.new([6], HOMOGRAPH_DICT, custom_leet)
      results = [] of String
      pipeline.run(["cat"]) { |w| results << w }
      results.should contain("c4t")
    end
  end
end
