require "./spec_helper"

module Worcestershire
  describe ResumeState do
    it "saves and loads state" do
      state = ResumeState.new(last_word: "test", combinations_done: [1, 2], position: 123_u64)
      with_tempfile("state", ".json") do |path|
        state.save(path)
        loaded = ResumeState.load(path)
        loaded.should_not be_nil
        loaded.try(&.last_word).should eq("test")
        loaded.try(&.combinations_done).should eq([1, 2])
        loaded.try(&.position).should eq(123_u64)
      end
    end

    it "round-trips a large position value (> Int32::MAX)" do
      large_pos = (Int32::MAX.to_u64 + 1_u64)
      state = ResumeState.new(position: large_pos)
      with_tempfile("state_large", ".json") do |path|
        state.save(path)
        loaded = ResumeState.load(path)
        loaded.should_not be_nil
        loaded.try(&.position).should eq(large_pos)
      end
    end

    it "returns nil if file does not exist" do
      ResumeState.load("nonexistent_state_file.json").should be_nil
    end

    it "returns nil if JSON is invalid" do
      with_tempfile("bad", ".json") do |path|
        File.write(path, "{invalid")
        ResumeState.load(path).should be_nil
      end
    end
  end
end
