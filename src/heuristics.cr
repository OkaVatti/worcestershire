module Worcestershire
  module Heuristics
    extend self

    def suggest_combinations(words : Array(String)) : Array(Int32)
      return [] of Int32 if words.empty?

      suggestions = [] of Int32

      # Digit presence -> leet and saltify
      if words.any? { |w| w =~ /\d/ }
        suggestions << 6
        suggestions << 5
      end

      # Mixed case -> case alternate
      if words.any? { |w| w =~ /[A-Z]/ && w =~ /[a-z]/ }
        suggestions << 2
      end

      # Multiple words -> word mix and separator
      if words.size >= 2
        suggestions << 1
        suggestions << 7
      end

      # Long words (> 8 chars) -> reverser (long reversals are distinct)
      if words.any? { |w| w.size > 8 }
        suggestions << 4
      end

      # Words with ASCII letters that have keyboard neighbours -> keyboard walk
      if words.any? { |w| w =~ /[a-zA-Z]/ }
        suggestions << 9
      end

      # Pure-alpha words (likely names/dictionary words) -> homograph and affix
      if words.all? { |w| w =~ /^[a-zA-Z]+$/ }
        suggestions << 3
        suggestions << 8
      end

      # Short words (all <= 6 chars) -> date variation is effective
      avg_len = words.sum(0) { |w| w.size } / words.size
      if avg_len <= 6
        suggestions << 10
      end

      # Always include common catches not yet added
      [3, 4, 8].each { |t| suggestions << t unless suggestions.includes?(t) }

      suggestions.uniq.sort
    end
  end
end
