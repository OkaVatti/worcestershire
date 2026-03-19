require "./spec_helper"

module Worcestershire
  describe LRUCache do
    it "caches values" do
      cache = LRUCache(String, String).new(2)
      cache.fetch("a") { "1" }.should eq("1")
      cache.fetch("a") { "2" }.should eq("1") # cached
    end

    it "evicts least recently used" do
      cache = LRUCache(String, String).new(2)
      cache.fetch("a") { "1" }
      cache.fetch("b") { "2" }
      cache.fetch("a") { "3" }                # a becomes most recent
      cache.fetch("c") { "4" }                # should evict b
      cache.fetch("b") { "5" }.should eq("5") # not cached
    end
  end
end
