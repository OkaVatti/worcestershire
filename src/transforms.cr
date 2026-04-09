# Shared single-word transformation logic.
# Both Generator and TransformPipeline use this module so that
# custom-dictionary state is never duplicated between the two.
require "./dictionaries"

module Worcestershire
  module Transforms
    extend self

    # All case variants of *word*.
    # Words longer than 10 characters produce only three variants to avoid
    # 2^n combinatorial explosion.
    def case_variants(word : String) : Array(String)
      if word.size <= 10
        result = [] of String
        (0...2 ** word.size).each do |mask|
          variant = word.chars.map_with_index do |c, i|
            mask.bit(i) == 1 ? c.upcase : c.downcase
          end.join
          result << variant
        end
        result.uniq
      else
        [word.downcase, word.upcase, word.capitalize]
      end
    end

    # Positional homograph substitutions.
    def homograph_variants(word : String,
                           dict : Hash(Char, Array(String)) = HOMOGRAPH_DICT) : Array(String)
      variants = [word]
      word.chars.each_with_index do |char, idx|
        next unless subs = dict[char]?
        new_variants = [] of String
        subs.each do |sub|
          variants.each do |var|
            chars = var.chars
            chars[idx] = sub[0]
            new_variants << chars.join
          end
        end
        variants.concat(new_variants)
      end
      variants.uniq
    end

    # Reversed word.
    def reverse_variant(word : String) : String
      word.reverse
    end

    # Salt prepend/append variants.
    def saltify_variants(word : String,
                         salt_dict : Array(String) = SALT_DICT) : Array(String)
      result = [] of String
      salt_dict.each do |salt|
        result << salt + word
        result << word + salt
      end
      result
    end

    # Positional leet substitutions.
    def leet_variants(word : String,
                      dict : Hash(Char, Array(String)) = LEET_DICT) : Array(String)
      variants = [word]
      word.chars.each_with_index do |char, idx|
        next unless subs = dict[char]?
        new_variants = [] of String
        subs.each do |sub|
          variants.each do |var|
            chars = var.chars
            chars[idx] = sub[0]
            new_variants << chars.join
          end
        end
        variants.concat(new_variants)
      end
      variants.uniq
    end

    # Affix prepend/append variants.
    def affix_variants(word : String,
                       affixes : Array(String) = DEFAULT_AFFIXES) : Array(String)
      result = [] of String
      affixes.each do |affix|
        result << affix + word
        result << word + affix
      end
      result
    end

    # Single-character keyboard-adjacency substitutions (QWERTY).
    # One variant per (position, adjacent-key) pair, preserving original case.
    def keyboard_variants(word : String) : Array(String)
      variants = [] of String
      word.chars.each_with_index do |char, idx|
        next unless adj_str = QWERTY_ADJACENT[char.downcase]?
        adj_str.each_char do |adj|
          adj_char = char.uppercase? ? adj.upcase : adj
          chars = word.chars
          chars[idx] = adj_char
          variants << chars.join
        end
      end
      variants.uniq
    end

    # Date string prepend/append variants.
    def date_variants(word : String,
                      date_strings : Array(String) = DATE_STRINGS) : Array(String)
      result = [] of String
      date_strings.each do |ds|
        result << word + ds
        result << ds + word
      end
      result
    end

    # Dispatch a single combination type to the appropriate transform.
    # Types 1 and 7 require multiple words and cannot be handled here;
    # they are processed separately in Generator.
    def apply(combo_type : Int32,
              word : String,
              homograph_dict : Hash(Char, Array(String)) = HOMOGRAPH_DICT,
              leet_dict : Hash(Char, Array(String)) = LEET_DICT,
              salt_dict : Array(String) = SALT_DICT,
              affixes : Array(String) = DEFAULT_AFFIXES,
              date_strings : Array(String) = DATE_STRINGS) : Array(String)
      case combo_type
      when  2 then case_variants(word)
      when  3 then homograph_variants(word, homograph_dict)
      when  4 then [reverse_variant(word)]
      when  5 then saltify_variants(word, salt_dict)
      when  6 then leet_variants(word, leet_dict)
      when  8 then affix_variants(word, affixes)
      when  9 then keyboard_variants(word)
      when 10 then date_variants(word, date_strings)
      else         [word]
      end
    end
  end
end
