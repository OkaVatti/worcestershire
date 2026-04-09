require "bit_array"

# Probabilistic deduplication filter.
# Uses five FNV-1a-derived hash functions over a shared bit array.
# At 10 M insertions with the default 100 M-bit array (12.5 MB),
# the expected false-positive rate is below 1 %.
module Worcestershire
  class BloomFilter
    # Two independent FNV-1a seeds for double-hashing (h1 + i*h2).
    FNV_OFFSET = 0x811c9dc5_u32
    FNV_PRIME  = 0x01000193_u32
    FNV_SEED2  = 0x9747b28c_u32
    NUM_HASHES =              5

    @bits : BitArray
    @m : Int32
    @mutex : Mutex

    def initialize(capacity : Int32 = 10_000_000)
      # m chosen so that (capacity * 10) bits give ~1 % false-positive rate
      # at capacity insertions with NUM_HASHES hash functions.
      m64 = (capacity.to_i64 * 10).clamp(1_000_000_i64, 100_000_000_i64)
      @m = m64.to_i32
      @bits = BitArray.new(@m)
      @mutex = Mutex.new
    end

    # Insert *word* and return true if it had not been seen before.
    # Thread-safe.
    def insert_new?(word : String) : Bool
      positions = compute_positions(word)
      @mutex.synchronize do
        seen = positions.all? { |p| @bits[p] }
        unless seen
          positions.each { |p| @bits[p] = true }
        end
        !seen
      end
    end

    private def fnv1a(word : String, seed : UInt32) : UInt32
      h = seed
      word.bytes.each do |b|
        h ^= b.to_u32
        h = h &* FNV_PRIME
      end
      h
    end

    private def compute_positions(word : String) : Array(Int32)
      h1 = fnv1a(word, FNV_OFFSET)
      h2 = fnv1a(word, FNV_SEED2)
      m = @m.to_u64
      Array.new(NUM_HASHES) do |i|
        ((h1.to_u64 &+ (i.to_u64 &* h2.to_u64)) % m).to_i32
      end
    end
  end
end
