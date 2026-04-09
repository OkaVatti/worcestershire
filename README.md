# worcestershire

A high-performance wordlist generator written in Crystal. Spiritual successor to Wister.

Worcestershire combines multiple transformation strategies into a single concurrent pipeline with streaming output. Words are never held in memory all at once; results are written directly to disk as they are produced.

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [From source](#from-source)
  - [Docker](#docker)
- [Quick start](#quick-start)
- [Usage](#usage)
  - [Options reference](#options-reference)
  - [Combination types](#combination-types)
  - [Transformation pipeline](#transformation-pipeline)
  - [Pattern generation](#pattern-generation)
  - [Deduplication](#deduplication)
  - [Output delimiter](#output-delimiter)
  - [Benchmark](#benchmark)
  - [Output formats](#output-formats)
  - [Encoding and hashing](#encoding-and-hashing)
  - [Presets](#presets)
  - [Configuration file](#configuration-file)
  - [Rule files](#rule-files)
  - [Resume](#resume)
  - [Custom dictionaries](#custom-dictionaries)
  - [Interactive wizard](#interactive-wizard)
- [Shell completion](#shell-completion)
- [Examples](#examples)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- Ten combination types: Word Mix, Case Alternate, Homograph, Reverser, Saltify, Leet Speak, Separator Insert, Affix, Keyboard Walk, Date Variation
- Transformation pipeline: chain single-word transforms so each step's output feeds the next
- Pattern generation: produce words from typed positional patterns (`?w?d?d?d`)
- Probabilistic deduplication using a bloom filter (`--deduplicate`)
- Concurrent generation using Crystal fibers
- Streaming output - constant memory usage regardless of wordlist size
- Eight encoding and hashing algorithms: base64, base32, URL, hex, MD5, SHA1, SHA256, SHA512
- Three output formats: plain text, JSON, hashcat mask
- Gzip compression of output
- Expanded JTR-style rule engine: 24 commands including `T`, `{`, `}`, `[`, `]`, `f`, `q`, `sXY`, `'N`, `DN`, `iNX`, `oNX`, `@X`, `zN`, `ZN`, `p`
- Built-in homograph, leet, salt, separator, affix, and date dictionaries - all overridable
- Preset profiles for common use cases
- YAML configuration file support
- Resume support
- Memory limit enforcement
- Built-in benchmark (`--benchmark`)
- Progress bar and coloured terminal output
- Verbose and quiet modes
- Interactive setup wizard

---

## Requirements

- Crystal >= 1.19.1
- `shards` (bundled with Crystal)

---

## Installation

### From source

```sh
git clone https://github.com/okavatti/worcestershire.git
cd worcestershire
shards install
shards build --release
```

The compiled binary is placed at `bin/worcestershire`.

Optionally install system-wide:

```sh
install -m 0755 bin/worcestershire /usr/local/bin/worcestershire
```

### Docker

```sh
docker build -t worcestershire .
docker run --rm -v "$PWD":/data worcestershire -i /data/words.txt -o /data/output.lst
```

---

## Quick start

```sh
# Generate variations of two words
bin/worcestershire -w "password admin" -c 1 2 3 -o wordlist.txt

# Generate from a file using all combination types
bin/worcestershire -i base.txt -c 1 2 3 4 5 6 7 8 9 10 -o full.lst

# Chain transforms: case-alternate -> leet -> saltify
bin/worcestershire -i base.txt --pipeline 2,6,5 -o piped.lst

# Generate words matching a pattern
bin/worcestershire -i base.txt --pattern "?w?d?d?d?d" -o pattern.lst

# Deduplicate output across combination types
bin/worcestershire -i base.txt -c 1 2 3 6 --deduplicate -o deduped.lst

# Benchmark throughput on this machine
bin/worcestershire --benchmark

# Use the interactive wizard
bin/worcestershire --interactive
```

---

## Usage

```
worecstershire [options]
```

### Options reference

| Short | Long                 | Argument  | Default      | Description                                      |
| ----- | -------------------- | --------- | ------------ | ------------------------------------------------ |
| `-w`  | `--words`            | `WORDS`   |              | Space-separated words                            |
| `-i`  | `--input`            | `FILE`    |              | Input file, one word per line (repeatable)       |
| `-o`  | `--output`           | `FILE`    | `output.lst` | Output file                                      |
| `-c`  | `--combination`      | `COMBOS`  |              | Space-separated combination type numbers (1-10)  |
| `-d`  | `--depth`            | `DEPTH`   | `3`          | Word mix depth (2-5)                             |
| `-m`  | `--min`              | `MIN`     | `0`          | Minimum output word length                       |
| `-M`  | `--max`              | `MAX`     | `20`         | Maximum output word length                       |
| `-e`  | `--encode`           | `FORMAT`  |              | Encode/hash output (see below)                   |
|       | `--format`           | `FMT`     | `txt`        | Output format: `txt`, `json`, `hashcat`          |
|       | `--compress`         |           |              | Gzip-compress output                             |
|       | `--force`            |           |              | Overwrite output without prompting               |
|       | `--dry-run`          |           |              | Estimate count only; do not write                |
|       | `--quiet`            |           |              | Suppress all non-essential output                |
|       | `--max-combinations` | `N`       |              | Stop after N combinations                        |
|       | `--rules`            | `FILE`    |              | Apply JTR-style rule file                        |
|       | `--resume`           | `FILE`    |              | Resume from saved state file                     |
|       | `--log-file`         | `FILE`    |              | Write log messages to file                       |
|       | `--log-level`        | `LEVEL`   | `info`       | `debug`, `info`, `warn`, `error`                 |
|       | `--buffer-size`      | `BYTES`   | `1048576`    | Output buffer size in bytes                      |
|       | `--no-color`         |           |              | Disable coloured output                          |
|       | `--parallel`         |           |              | Enable multi-threading (requires `-Dpreview_mt`) |
|       | `--workers`          | `N`       | `4`          | Number of concurrent workers                     |
|       | `--cache-size`       | `N`       | `1000`       | Encoding LRU cache size                          |
|       | `--max-memory`       | `BYTES`   |              | Abort if memory usage exceeds this               |
|       | `--homograph-dict`   | `FILE`    |              | Custom homograph substitutions file              |
|       | `--leet-dict`        | `FILE`    |              | Custom leet substitutions file                   |
|       | `--salt-dict`        | `FILE`    |              | Custom salt dictionary file                      |
|       | `--affix-dict`       | `FILE`    |              | Custom affix dictionary file                     |
|       | `--config`           | `FILE`    |              | Load options from YAML config file               |
| `-l`  | `--list`             |           |              | List all combination types and exit              |
|       | `--preset`           | `NAME`    |              | Apply a named preset                             |
|       | `--suggest`          |           |              | Analyse input and suggest combinations           |
| `-V`  | `--verbose`          |           |              | Verbose output                                   |
| `-N`  | `--noprogress`       |           |              | Disable progress bar                             |
|       | `--examples`         |           |              | Print usage examples and exit                    |
|       | `--explain`          | `COMBOS`  |              | Explain selected combination types               |
|       | `--interactive`      |           |              | Run interactive setup wizard                     |
|       | `--pipeline`         | `STEPS`   |              | Chain transforms: comma-separated type numbers   |
|       | `--deduplicate`      |           |              | Remove duplicate output words (bloom filter)     |
|       | `--output-delimiter` | `STR`     | `""`         | Delimiter for Word Mix joins                     |
|       | `--benchmark`        |           |              | Run built-in benchmark and report words/sec      |
|       | `--pattern`          | `PATTERN` |              | Generate words from a typed positional pattern   |
| `-v`  | `--version`          |           |              | Print version and exit                           |
| `-h`  | `--help`             |           |              | Print help and exit                              |

### Combination types

| Number | Name             | Description                                                                   |
| ------ | ---------------- | ----------------------------------------------------------------------------- |
| `1`    | Word Mix         | Concatenates permutations of input words up to `--depth`                      |
| `2`    | Case Alternate   | All case variants (`password`, `PASSWORD`, `Password`, ...)                   |
| `3`    | Homograph        | Substitutes chars with visual look-alikes (`a` -> `@`, `4`, `α`)              |
| `4`    | Reverser         | Reverses each word (`password` -> `drowssap`)                                 |
| `5`    | Saltify          | Prepends/appends salt dictionary entries                                      |
| `6`    | Leet Speak       | Applies leet substitutions (`e` -> `3`, `s` -> `5`)                           |
| `7`    | Separator Insert | Joins word pairs/triples with separator characters (`pass-word`, `pass_word`) |
| `8`    | Affix            | Prepends/appends common affixes (`!password`, `password2024`)                 |
| `9`    | Keyboard Walk    | Substitutes each character with its QWERTY-adjacent keys                      |
| `10`   | Date Variation   | Appends/prepends date strings (`password2024`, `01012000password`)            |

Run `bin/worcestershire --explain 9 10` for detailed descriptions.

### Transformation pipeline

`--pipeline` applies a sequence of single-word transforms where the full output of each step becomes the input of the next. This multiplies the mutation space far beyond what individual combination types produce alone.

Valid pipeline steps: 2, 3, 4, 5, 6, 8, 9, 10 (types 1 and 7 require multiple words and cannot be pipelined).

```sh
# Case-alternate -> leet -> saltify
bin/worcestershire -i words.txt --pipeline 2,6,5 -o piped.lst

# Reverse -> keyboard walk -> affix
bin/worcestershire -i words.txt --pipeline 4,9,8 -o piped.lst
```

When `--pipeline` is set it replaces `--combination`. Combine `--pipeline` with `--deduplicate`, `--encode`, and length filters as normal.

The pipeline computes intermediates in memory before writing, so it is best suited to input sets of a few thousand words or fewer. For larger inputs, use `--combination` with individual types.

### Pattern generation

`--pattern` generates words by expanding typed positional tokens:

| Token | Expands to                                |
| ----- | ----------------------------------------- |
| `?w`  | each input word                           |
| `?d`  | digit `0`-`9`                             |
| `?l`  | lowercase letter `a`-`z`                  |
| `?u`  | uppercase letter `A`-`Z`                  |
| `?s`  | special character `!@#$%^&*()-_+=`        |
| `?a`  | alpha (`a`-`z` + `A`-`Z`)                 |
| `?n`  | alphanumeric (alpha + digits)             |
| `?x`  | any printable (alpha + digits + specials) |
| `??`  | literal `?`                               |
| other | literal character                         |

```sh
# Each word followed by every four-digit combination
bin/worcestershire -i words.txt --pattern "?w?d?d?d?d" -o pattern.lst

# Static prefix, word, year suffix
bin/worcestershire -i words.txt --pattern "admin_?w_?d?d?d?d" -o pattern.lst
```

Pattern generation replaces `--combination` and `--pipeline`. Apply `--max-combinations` to cap output size.

### Deduplication

`--deduplicate` uses a bloom filter to suppress duplicate words across all combination types. This is useful when running many types simultaneously (e.g., types 1, 2, 3, 6) where different transforms can produce the same string.

```sh
bin/worcestershire -i words.txt -c 1 2 3 6 --deduplicate -o deduped.lst
```

The filter uses approximately 12.5 MB of memory for up to 10 million unique words, with a false-positive rate below 1 %. A false positive means an occasional unique word is silently dropped; no duplicate will ever be passed through.

### Output delimiter

`--output-delimiter` controls the string placed between words when using Word Mix (type 1). The default is an empty string (direct concatenation). Type 7 (Separator Insert) remains independent and uses its own built-in separator set.

```sh
# Produce "pass-word" and "word-pass" instead of "password"
bin/worcestershire -w "pass word" -c 1 --output-delimiter "-" -o out.lst
```

### Benchmark

`--benchmark` runs a fixed internal test case and reports words generated per second. Use this to compare performance across machines or after code changes.

```sh
bin/worcestershire --benchmark
```

### Output formats

- `txt` - one word per line (default)
- `json` - one JSON object per line: `{"word":"value"}`
- `hashcat` - one word per line, compatible with hashcat wordlist input

### Encoding and hashing

Pass one of the following to `-e` / `--encode`:

`base64`, `base32`, `url`, `hex`, `md5`, `sha1`, `sha256`, `sha512`

### Presets

| Name                | Combinations | Depth | Min | Max | Encoding | Format | Compress | Limit      |
| ------------------- | ------------ | ----- | --- | --- | -------- | ------ | -------- | ---------- |
| `password-cracking` | 1-8          | 4     | 8   | 32  | -        | txt    | yes      | 10,000,000 |
| `username-enum`     | 2, 4, 7      | 2     | 4   | 20  | -        | txt    | no       | 1,000,000  |
| `quick-test`        | 1, 2         | 2     | 0   | 20  | base64   | json   | no       | 1,000      |

```sh
bin/worcestershire -i names.txt --preset username-enum -o users.lst
```

### Configuration file

Any option that can be set on the command line can be set in a YAML file and loaded with `--config`. Command-line flags always override config file values.

```yaml
# worcestershire.yml
depth: 4
min_length: 8
max_length: 32
format: txt
compress: true
max_combinations: 5000000
buffer_size: 2097152
workers: 8
cache_size: 500
deduplicate: true
output_delimiter: "-"
combinations:
  - 1
  - 2
  - 3
  - 5
```

New keys supported: `deduplicate` (boolean), `output_delimiter` (string), `pipeline` (list of integers).

### Rule files

Rule files apply JTR-style transformations to each word. Each non-comment line is one rule applied left to right.

| Command | Effect                                             |
| ------- | -------------------------------------------------- |
| `l`     | Lowercase                                          |
| `u`     | Uppercase                                          |
| `c`     | Capitalise (first upper, rest lower)               |
| `C`     | Inverse capitalise (first lower, rest upper)       |
| `r`     | Reverse                                            |
| `d`     | Duplicate (`pass` -> `passpass`)                   |
| `f`     | Reflect (`pass` -> `passssap`)                     |
| `{`     | Rotate left (`abcd` -> `bcda`)                     |
| `}`     | Rotate right (`abcd` -> `dabc`)                    |
| `[`     | Delete first character                             |
| `]`     | Delete last character                              |
| `q`     | Duplicate each character (`ab` -> `aabb`)          |
| `p`     | Pluralise (append `s` unless word ends in `s`/`S`) |
| `T`     | Toggle case of every character                     |
| `TN`    | Toggle case of character at JTR position N         |
| `sXY`   | Substitute all occurrences of char X with char Y   |
| `'N`    | Truncate to N characters (JTR position encoding)   |
| `DN`    | Delete character at JTR position N                 |
| `iNX`   | Insert character X before JTR position N           |
| `oNX`   | Overwrite character at JTR position N with X       |
| `@X`    | Delete all occurrences of character X              |
| `zN`    | Duplicate first character N times                  |
| `ZN`    | Duplicate last character N times                   |
| `$X`    | Append character X (`$` alone appends `!`)         |
| `^X`    | Prepend character X (`^` alone prepends `!`)       |
| `#`     | Skip remainder of rule (inline comment)            |

JTR position encoding: `0`-`9` map to positions 0-9, `A`-`Z` map to positions 10-35.

```sh
bin/worcestershire -i words.txt --rules myrules.rule -o output.lst
```

### Resume

```sh
bin/worcestershire -i words.txt -c 1 2 -o part1.lst --max-combinations 100000 --resume state.json
bin/worcestershire -i words.txt -c 1 2 -o part2.lst --resume state.json --force
```

### Custom dictionaries

| Flag                    | Format                               |
| ----------------------- | ------------------------------------ |
| `--homograph-dict FILE` | One `char->sub1,sub2` entry per line |
| `--leet-dict FILE`      | One `char->sub1,sub2` entry per line |
| `--salt-dict FILE`      | One salt value per line              |
| `--affix-dict FILE`     | One affix value per line             |

### Interactive wizard

```sh
bin/worcestershire
bin/worcestershire --interactive
```

---

## Shell completion

Completion scripts for bash, zsh, fish, and POSIX sh are in `contrib/`.

| Shell    | File                          |
| -------- | ----------------------------- |
| bash     | `contrib/bash_completion.sh`  |
| zsh      | `contrib/zsh_completion.zsh`  |
| fish     | `contrib/worcestershire.fish` |
| POSIX sh | `contrib/sh_completion.sh`    |

---

## Examples

| Script                          | Description                                  |
| ------------------------------- | -------------------------------------------- |
| `examples/basic_wordlist.sh`    | Simple word-mix and case-alternate run       |
| `examples/password_cracking.sh` | Full pipeline for offline password cracking  |
| `examples/username_enum.sh`     | Username variation generation                |
| `examples/hash_wordlist.sh`     | Generate SHA256-hashed wordlist              |
| `examples/resume_run.sh`        | Interruptible run with resume                |
| `examples/custom_dicts.sh`      | Using custom homograph and salt dictionaries |
| `examples/with_rules.sh`        | Applying a JTR-style rule file               |
| `examples/docker_run.sh`        | Running via Docker                           |

---

## Development

```sh
crystal spec
crystal spec --error-trace
bin/ameba
shards build
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b my-feature`)
3. Commit your changes
4. Push and open a pull request

Run `crystal spec` and `bin/ameba` before submitting.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Contributors

- [OkaVatti](https://github.com/OkaVatti) - creator and maintainer (Lily / Oka / AVA)
