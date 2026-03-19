module Worcestershire
  # Simple rule interpreter (similar to JTR but limited)
  class RuleEngine
    @rules : Array(String)

    def initialize(rule_file : String)
      @rules = [] of String # ensure always initialized
      begin
        @rules = File.read_lines(rule_file).map(&.strip).reject(&.empty?)
      rescue e : File::NotFoundError
        Utils.print_error("Rule file not found: #{rule_file}")
        exit(1)
      end
    end

    # Apply all rules to a word, returning an array of transformed words
    def apply(word : String) : Array(String)
      results = [word]
      @rules.each do |rule|
        w = word.dup
        rule.chars.each do |cmd|
          case cmd
          when 'l' then w = w.downcase
          when 'u' then w = w.upcase
          when 'c' then w = w.capitalize
          when 'r' then w = w.reverse
          when 'd' then w = w + w   # duplicate
          when '$' then w = w + "!" # append !
          when '^' then w = "!" + w # prepend !
          # Add more as needed
          else
            # ignore unknown
          end
        end
        results << w
      end
      results.uniq
    end
  end
end
