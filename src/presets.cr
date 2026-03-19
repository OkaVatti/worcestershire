module Worcestershire
  PRESETS = {
    "password-cracking" => {
      combinations:     [1, 2, 3, 4, 5, 6, 7, 8],
      depth:            4,
      min_length:       8,
      max_length:       32,
      encoding:         nil,
      format:           "txt",
      compress:         true,
      max_combinations: 10_000_000_u64,
      description:      "Typical for password cracking – all combos, moderate depth",
    },
    "username-enum" => {
      combinations:     [2, 4, 7],
      depth:            2,
      min_length:       4,
      max_length:       20,
      encoding:         nil,
      format:           "txt",
      compress:         false,
      max_combinations: 1_000_000_u64,
      description:      "Generate username variations",
    },
    "quick-test" => {
      combinations:     [1, 2],
      depth:            2,
      min_length:       0,
      max_length:       20,
      encoding:         "base64",
      format:           "json",
      compress:         false,
      max_combinations: 1000_u64,
      description:      "Small test run",
    },
  }

  def self.apply_preset(name : String, options : Options) : Options
    preset = PRESETS[name]?
    return options unless preset

    options.combinations = preset[:combinations] if options.combinations.empty?
    options.depth = preset[:depth] if options.depth == 3 # only if default
    options.min_length = preset[:min_length] if options.min_length == 0
    options.max_length = preset[:max_length] if options.max_length == 20
    options.encoding = preset[:encoding] if options.encoding.nil?
    options.format = preset[:format] if options.format == "txt"
    options.compress = preset[:compress] unless options.compress
    options.max_combinations = preset[:max_combinations] if options.max_combinations.nil?
    options
  end
end
