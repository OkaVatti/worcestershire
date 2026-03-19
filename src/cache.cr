module Worcestershire
  class LRUCache(K, V)
    @cache = {} of K => V
    @order = [] of K
    @max_size : Int32

    def initialize(@max_size = 1000)
    end

    def fetch(key : K, &block : -> V) : V
      if value = @cache[key]?
        # move to front (most recent)
        @order.delete(key)
        @order << key
        return value
      end

      value = yield
      if @cache.size >= @max_size
        # evict least recently used (first in order)
        lru = @order.shift?
        @cache.delete(lru) if lru
      end
      @cache[key] = value
      @order << key
      value
    end
  end
end
