module Worcestershire
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

  SALT_DICT = [
    "123", "1234", "12345", "123456", "1234567", "12345678", "123456789",
    "0123456789", "1234567890",
    "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "+", "=",
    "2020", "2021", "2022", "2023", "2024", "2025", "2026", "2027", "2028",
    "2029", "2030",
    "admin", "administrator", "root", "user", "pass", "password",
    "password123", "password123!",
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

  SEPARATORS = ["-", "_", ".", "+", " ", "", "@"]

  DEFAULT_AFFIXES = ["!", "?", "123", "2024", "admin", "root"]

  # QWERTY keyboard adjacency map (lowercase keys only).
  # Values are strings of adjacent characters.
  QWERTY_ADJACENT = {
    'q' => "wa",       'w' => "qeas",     'e' => "wrds",
    'r' => "etfd",     't' => "rygf",     'y' => "tuhg",
    'u' => "yijh",     'i' => "uokj",     'o' => "iplk",
    'p' => "ol",
    'a' => "qwsz",     's' => "awedzx",   'd' => "serfxc",
    'f' => "drtgcv",   'g' => "ftyhvb",   'h' => "gyujbn",
    'j' => "huiknm",   'k' => "jiom",     'l' => "kop",
    'z' => "asx",      'x' => "zsdc",     'c' => "xdfv",
    'v' => "cfgb",     'b' => "vghn",     'n' => "bhjm",
    'm' => "njk",
  }

  # Date strings used by the Date Variation combination type.
  DATE_STRINGS = [
    # Four-digit years
    "1990", "1991", "1992", "1993", "1994", "1995", "1996", "1997", "1998",
    "1999", "2000", "2001", "2002", "2003", "2004", "2005", "2006", "2007",
    "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016",
    "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025",
    "2026",
    # Two-digit years
    "90", "91", "92", "93", "94", "95", "96", "97", "98", "99",
    "00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
    "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
    "20", "21", "22", "23", "24", "25", "26",
    # Common MMDD and DDMM patterns
    "0101", "1231", "0704", "1225", "0314", "0420", "1010", "0909",
    # Full date stamps
    "01012024", "01012023", "01012000", "01011990",
    # Special numeric suffixes
    "1", "12", "100", "007", "001", "666", "777", "999", "000",
  ]

  COMBINATION_TYPES = {
    1  => "Word Mix",
    2  => "Case Alternate",
    3  => "Homograph",
    4  => "Reverser",
    5  => "Saltify",
    6  => "Leet Speak",
    7  => "Separator Insert",
    8  => "Affix (Prefix/Suffix)",
    9  => "Keyboard Walk",
    10 => "Date Variation",
  }
end