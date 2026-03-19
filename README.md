# worcestershire

TODO: Write a description here

## Features
- All five original combination types (Word Mix, Case Alternate, Homograph, Reverser, Saltify)
- Concurrent generation using Crystal fibers (multi‑core ready)
- Streaming output – no memory explosion
- Encoding/decoding: base64, base32, URL, MD5, SHA1, SHA256, SHA512
- Built‑in homograph and salt dictionaries (customizable)
- Progress bar and colored terminal output
- Length filtering, verbose mode, and more

## Installation
```bash
git clone git@github.com:okavatti/worcestershire.git
cd worcestershire
shards build --release
bin/worcestershire --help
```

## Usage

```text
worcestershire [options]

Options:
    -w, --words WORD1 WORD2 ...  // Space-separated words
    -i, --input FILE             // Input file (one word per line)
    -c, --combination 1 2 3 ...  // Combination types (1-5)
    -d, --depth DEPTH            // Word mix depth (default: 3)
    -m, --min MIN                // Minimum word length (default: 0)
    -M, --max MAX                // Maximum word length (default: 20)
    -e, --encode FORMAT          // Encode output: base64, base32, url, md5, sha1, sha256, sha512
    --decode FORMAT              // Decode input before processing: base64, base32, url
    -o, --output FILE            // Output file (default: output.lst)
    --no-progress                // Disable progress spinner
    -v, --verbose                // Verbose output
    --homograph FILE             // Custom homograph dictionary (YAML)
    --salt FILE                  // Custom salt dictionary (text file)
    -h, --help                   // Show this help
```

See --help for all options.

## Combination types

1. Word Mix         – Combine multiple words (depth controls how many)
2. Case Alternate   – Generate case variations
3. Homograph        – Substitute characters with lookalikes (e.g., a → @, e → 3)
4. Reverser         – Reverse each word
5. Saltify          – Add common prefixes/suffixes

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/worcestershire/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [OkaVatti](https://github.com/OkaVatti) - creator and maintainer
    - Aka "Lily", "Oka", "AVA"