require "./spec_helper"

module Worcestershire
  describe BloomFilter do
    it "returns true for a new word" do
      bf = BloomFilter.new(1000)
      bf.insert_new?("hello").should be_true
    end

    it "returns false for a previously inserted word" do
      bf = BloomFilter.new(1000)
      bf.insert_new?("hello")
      bf.insert_new?("hello").should be_false
    end

    it "distinguishes different words" do
      bf = BloomFilter.new(1000)
      bf.insert_new?("alpha")
      bf.insert_new?("beta").should be_true
    end

    it "handles many unique insertions without false positives on seen words" do
      bf = BloomFilter.new(10_000)
      seen = [] of String
      fp = 0
      10_000.times do |i|
        word = "word#{i}"
        bf.insert_new?(word)
        seen << word
      end
      seen.each do |w|
        fp += 1 unless bf.insert_new?(w) == false
      end
      # All previously inserted words must return false (not new)
      fp.should eq(0)
    end
  end
end
