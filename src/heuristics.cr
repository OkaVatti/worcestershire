module Worcestershire
  module Heuristics
    extend self

    def suggest_combinations(words : Array(String)) : Array(Int32)
      suggestions = [] of Int32

      # Check for digits -> suggest leet and saltify
      if words.any? { |w| w =~ /\d/ }
        suggestions << 6 # leet
        suggestions << 5 # saltify
      end

      # Check for mixed case -> suggest case alternate
      if words.any? { |w| w =~ /[A-Z]/ && w =~ /[a-z]/ }
        suggestions << 2 # case alternate
      end

      # Check for long words (>8 chars) -> suggest word mix
      if words.any? { |w| w.size > 8 }
        suggestions << 1 # word mix
      end

      # Always include common useful combos
      suggestions << 3 # homograph
      suggestions << 4 # reverser
      suggestions << 7 # separator
      suggestions << 8 # affix

      suggestions.uniq.sort
    end
  end
end
