require "./utils"

module Worcestershire
  # JTR-style rule engine.
  #
  # Supported single-character commands:
  #   l        lowercase
  #   u        uppercase
  #   c        capitalise (first char upper, rest lower)
  #   C        inverse capitalise (first char lower, rest upper)
  #   r        reverse
  #   d        duplicate   (passpass)
  #   f        reflect     (passssap)
  #   {        rotate left  (asswordp)
  #   }        rotate right (dpasswor)
  #   [        delete first character
  #   ]        delete last character
  #   q        duplicate each character (ppaasss)
  #   p        pluralise (append 's' if word does not already end in 's' or 'S')
  #   T        toggle case of every character
  #   TN       toggle case of character at position N (JTR position encoding)
  #   sXY      substitute all occurrences of char X with char Y
  #   'N       truncate to N characters (JTR position encoding)
  #   DN       delete character at position N
  #   iNX      insert character X before position N
  #   oNX      overwrite character at position N with X
  #   @X       delete all occurrences of character X
  #   zN       duplicate first character N times
  #   ZN       duplicate last character N times
  #   $X       append character X  ($  alone appends '!')
  #   ^X       prepend character X (^  alone prepends '!')
  #   #        skip remainder of rule (inline comment)
  #
  # Position N uses JTR encoding: '0'-'9' -> 0-9, 'A'-'Z' -> 10-35.
  # Unknown commands are silently ignored.
  # Lines starting with '#' are treated as comments and skipped entirely.
  class RuleEngine
    @rules : Array(String)

    def initialize(rule_file : String)
      @rules = [] of String
      begin
        @rules = File.read_lines(rule_file)
          .map(&.strip)
          .reject { |l| l.empty? || l.starts_with?('#') }
      rescue e : File::NotFoundError
        Utils.print_error("Rule file not found: #{rule_file}")
        exit(1)
      end
    end

    # Apply every rule to *word* and return an array of all results
    # (including the original word) deduplicated.
    def apply(word : String) : Array(String)
      results = [word]
      @rules.each do |rule|
        results << apply_rule(word, rule)
      end
      results.uniq
    end

    private def apply_rule(word : String, rule : String) : String
      w = word.dup
      i = 0
      while i < rule.size
        cmd = rule[i]
        case cmd
        when 'l'
          w = w.downcase
          i += 1
        when 'u'
          w = w.upcase
          i += 1
        when 'c'
          w = w.capitalize
          i += 1
        when 'C'
          # Inverse capitalise: first char lower, rest upper
          w = w.size > 0 ? w[0].to_s.downcase + w[1..].upcase : w
          i += 1
        when 'r'
          w = w.reverse
          i += 1
        when 'd'
          w = w + w
          i += 1
        when 'f'
          w = w + w.reverse
          i += 1
        when '{'
          w = w.size > 1 ? w[1..] + w[0].to_s : w
          i += 1
        when '}'
          w = w.size > 1 ? w[-1].to_s + w[0..-2] : w
          i += 1
        when '['
          w = w.size > 0 ? w[1..] : w
          i += 1
        when ']'
          w = w.size > 0 ? w[0..-2] : w
          i += 1
        when 'q'
          w = w.chars.map { |c| "#{c}#{c}" }.join
          i += 1
        when 'p'
          last = w.size > 0 ? w[-1] : '\0'
          w = w + "s" unless last == 's' || last == 'S'
          i += 1
        when 'T'
          if i + 1 < rule.size && (n = jtr_pos?(rule[i + 1]))
            # Toggle case at position n
            chars = w.chars
            if n < chars.size
              chars[n] = chars[n].uppercase? ? chars[n].downcase : chars[n].upcase
              w = chars.join
            end
            i += 2
          else
            # Toggle all
            w = w.chars.map { |c| c.uppercase? ? c.downcase : c.upcase }.join
            i += 1
          end
        when 's'
          if i + 2 < rule.size
            from_char = rule[i + 1]
            to_char = rule[i + 2]
            w = w.gsub(from_char, to_char.to_s)
            i += 3
          else
            i += 1
          end
        when '\''
          if i + 1 < rule.size
            n = jtr_pos(rule[i + 1])
            w = w[0, [n, w.size].min]
            i += 2
          else
            i += 1
          end
        when 'D'
          if i + 1 < rule.size
            n = jtr_pos(rule[i + 1])
            chars = w.chars
            chars.delete_at(n) if n < chars.size
            w = chars.join
            i += 2
          else
            i += 1
          end
        when 'i'
          if i + 2 < rule.size
            n = jtr_pos(rule[i + 1])
            ins = rule[i + 2]
            chars = w.chars
            n = chars.size if n > chars.size
            chars.insert(n, ins)
            w = chars.join
            i += 3
          else
            i += 1
          end
        when 'o'
          if i + 2 < rule.size
            n = jtr_pos(rule[i + 1])
            repl = rule[i + 2]
            chars = w.chars
            chars[n] = repl if n < chars.size
            w = chars.join
            i += 3
          else
            i += 1
          end
        when '@'
          if i + 1 < rule.size
            del_char = rule[i + 1]
            w = w.gsub(del_char.to_s, "")
            i += 2
          else
            i += 1
          end
        when 'z'
          if i + 1 < rule.size
            n = jtr_pos(rule[i + 1])
            w = w.size > 0 ? (w[0].to_s * n) + w : w
            i += 2
          else
            i += 1
          end
        when 'Z'
          if i + 1 < rule.size
            n = jtr_pos(rule[i + 1])
            w = w.size > 0 ? w + (w[-1].to_s * n) : w
            i += 2
          else
            i += 1
          end
        when '$'
          next_char = (i + 1 < rule.size) ? rule[i + 1] : '!'
          w = w + next_char.to_s
          i += (i + 1 < rule.size ? 2 : 1)
        when '^'
          next_char = (i + 1 < rule.size) ? rule[i + 1] : '!'
          w = next_char.to_s + w
          i += (i + 1 < rule.size ? 2 : 1)
        when '#'
          # Inline comment: skip rest of rule
          break
        else
          # Unknown command: skip
          i += 1
        end
      end
      w
    end

    # JTR position encoding: '0'-'9' -> 0-9, 'A'-'Z' -> 10-35.
    private def jtr_pos(c : Char) : Int32
      if c >= '0' && c <= '9'
        c.ord - '0'.ord
      elsif c >= 'A' && c <= 'Z'
        c.ord - 'A'.ord + 10
      else
        0
      end
    end

    # Returns nil for characters that are not valid JTR position digits.
    # Used to distinguish TN (toggle at position) from T (toggle all).
    private def jtr_pos?(c : Char) : Int32?
      if c >= '0' && c <= '9'
        c.ord - '0'.ord
      elsif c >= 'A' && c <= 'Z'
        c.ord - 'A'.ord + 10
      else
        nil
      end
    end
  end
end
