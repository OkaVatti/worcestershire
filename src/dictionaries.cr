module Worcestershire
  # Homograph dictionary for character substitutions
  HOMOGRAPH_DICT = {
    'a' => ["@", "4", "α", "а"],
    'b' => ["8", "6", "β", "в"],
    'c' => ["(", "<", "¢", "с"],
    'e' => ["3", "€", "ε", "е"],
    'g' => ["9", "6", "ğ", "г"],
    'i' => ["1", "!", "¡", "|", "ι", "і"],
    'l' => ["1", "|", "7", "ℓ", "լ"],
    'o' => ["0", "()", "°", "ο", "о"],
    's' => ["5", "$", "§", "ѕ"],
    't' => ["7", "+", "τ", "т"],
    'z' => ["2", "ʒ", "ζ", "z"],
  }

  # Common salt values
  SALT_DICT = [
    "123", "1234", "12345", "123456", "1234567", "12345678", "123456789", "0123456789", "1234567890",
    "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "+", "=",
    "2020", "2021", "2022", "2023", "2024", "2025", "2026", "2027", "2028", "2029", "2030",
    "admin", "administrator", "root", "user", "pass", "password", "password123", "password123!",
    "qwerty", "asdf", "zxcv", "abc", "xyz",
    "supersecretpassword", "supersecretsalt", "secret",
  ]

  LEET_DICT = {
    'a' => ["4", "@"],
    'b' => ["8"],
    'e' => ["3"],
    'g' => ["6", "9"],
    'i' => ["1", "!"],
    'l' => ["1", "|"],
    'o' => ["0"],
    's' => ["5", "$"],
    't' => ["7"],
    'z' => ["2"],
  }

  # Common separators for combination type
  SEPARATORS = ["-", "_", ".", "+", " ", "", "@"]

  # Default prefix/suffix dictionary (can be overridden by config)
  DEFAULT_AFFIXES = ["!", "?", "123", "2024", "admin", "root"]

  # Update combination types
  COMBINATION_TYPES = {
    1 => "Word Mix",
    2 => "Case Alternate",
    3 => "Homograph",
    4 => "Reverser",
    5 => "Saltify",
    6 => "Leet Speak",
    7 => "Separator Insert",
    8 => "Affix (Prefix/Suffix)",
  }
end
