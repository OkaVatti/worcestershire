# Transformation pipeline.
# Applies a sequence of single-word combination types in order,
# feeding each step's full output set into the next step as input.
#
# Example: steps [2, 6, 5] on ["pass"] will
#   1. Case Alternate ["pass"] -> ["pass", "PASS", "Pass", ...]
#   2. Leet Speak  each result -> ["p@ss", "P@SS", ...]
#   3. Saltify     each result -> ["123p@ss", "p@ss!", ...]
#
# Valid steps: 2, 3, 4, 5, 6, 8, 9, 10 (single-word transforms).
# Steps 1 and 7 (Word Mix, Separator Insert) require multiple words
# and cannot be used in a pipeline.
require "./transforms"
require "./dictionaries"

module Worcestershire
  class TransformPipeline
    VALID_STEPS = {2, 3, 4, 5, 6, 8, 9, 10}

    def initialize(@steps : Array(Int32),
                   @homograph_dict : Hash(Char, Array(String)) = HOMOGRAPH_DICT,
                   @leet_dict : Hash(Char, Array(String)) = LEET_DICT,
                   @salt_dict : Array(String) = SALT_DICT,
                   @affixes : Array(String) = DEFAULT_AFFIXES,
                   @date_strings : Array(String) = DATE_STRINGS)
    end

    def self.valid_step?(type : Int32) : Bool
      VALID_STEPS.includes?(type)
    end

    # Run the pipeline on *words* and yield each final result.
    # Uses yield (non-captured block) so the caller may use `break`.
    def run(words : Array(String), &)
      current = words.dup

      @steps.each do |step|
        next_set = [] of String
        current.each do |word|
          Transforms.apply(
            step, word,
            homograph_dict: @homograph_dict,
            leet_dict: @leet_dict,
            salt_dict: @salt_dict,
            affixes: @affixes,
            date_strings: @date_strings
          ).each { |v| next_set << v }
        end
        current = next_set.uniq
      end

      current.each { |w| yield w }
    end
  end
end
