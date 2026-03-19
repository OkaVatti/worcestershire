# worcestershire

A high-performance wordlist generator written in Crystal. Spiritual successor to Wister.

Worcester combines multiple transformation strategies — case alternation, homograph substitution, leet speak, word mixing, separator insertion, and more — into a single concurrent pipeline with streaming output. Words are never held in memory all at once; results are written directly to disk as they are produced.

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

- Eight combination types: Word Mix, Case Alternate, Homograph, Reverser, Saltify, Leet Speak, Separator Insert, Affix
- Concurrent generation using Crystal fibers
- Streaming output — constant memory usage regardless of wordlist size
- Eight encoding and hashing algorithms: base64, base32, URL, hex, MD5, SHA1, SHA256, SHA512
- Three output formats: plain text, JSON (one object per line), hashcat mask
- Gzip compression of output
- Built-in homograph, leet, salt, separator, and affix dictionaries — all overridable
- Preset profiles for common use cases
- YAML configuration file support
- JTR-style rule file interpreter
- Resume support — pick up a generation run where it was interrupted
- Memory limit enforcement
- Max-combinations limit
- Progress bar and coloured terminal output (disable with `--no-color`)
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

Optionally install it system-wide:

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
# Generate variations of two words and write to wordlist.txt
bin/worcestershire -w "password admin" -c 1 2 3 -o wordlist.txt

# Generate from a file using all combination types
bin/worcestershire -i base.txt -c 1 2 3 4 5 6 7 8 -o full.lst

# Use the interactive wizard
bin/worcestershire --interactive

# Ask worcestershire to suggest combination types based on the input
bin/worcestershire -i base.txt --suggest
```

---

## Usage

```
worcestershire [options]
```

### Options reference

| Short | Long                 | Argument | Default      | Description                                      |
| ----- | -------------------- | -------- | ------------ | ------------------------------------------------ |
| `-w`  | `--words`            | `WORDS`  |              | Space-separated words                            |
| `-i`  | `--input`            | `FILE`   |              | Input file, one word per line (repeatable)       |
| `-o`  | `--output`           | `FILE`   | `output.lst` | Output file                                      |
| `-c`  | `--combination`      | `COMBOS` |              | Space-separated combination type numbers (1-8)   |
| `-d`  | `--depth`            | `DEPTH`  | `3`          | Word mix depth (2-5)                             |
| `-m`  | `--min`              | `MIN`    | `0`          | Minimum output word length                       |
| `-M`  | `--max`              | `MAX`    | `20`         | Maximum output word length                       |
| `-e`  | `--encode`           | `FORMAT` |              | Encode/hash output (see below)                   |
|       | `--format`           | `FMT`    | `txt`        | Output format: `txt`, `json`, `hashcat`          |
|       | `--compress`         |          |              | Gzip-compress output                             |
|       | `--force`            |          |              | Overwrite output without prompting               |
|       | `--dry-run`          |          |              | Estimate count only, do not write                |
|       | `--quiet`            |          |              | Suppress all non-essential output                |
|       | `--max-combinations` | `N`      |              | Stop after N combinations                        |
|       | `--rules`            | `FILE`   |              | Apply JTR-style rule file                        |
|       | `--resume`           | `FILE`   |              | Resume from saved state file                     |
|       | `--log-file`         | `FILE`   |              | Write log messages to file                       |
|       | `--log-level`        | `LEVEL`  | `info`       | `debug`, `info`, `warn`, `error`                 |
|       | `--buffer-size`      | `BYTES`  | `1048576`    | Output buffer size in bytes                      |
|       | `--no-color`         |          |              | Disable coloured output                          |
|       | `--parallel`         |          |              | Enable multi-threading (requires `-Dpreview_mt`) |
|       | `--workers`          | `N`      | `4`          | Number of concurrent workers                     |
|       | `--cache-size`       | `N`      | `1000`       | Encoding LRU cache size                          |
|       | `--max-memory`       | `BYTES`  |              | Abort if memory usage exceeds this               |
|       | `--homograph-dict`   | `FILE`   |              | Custom homograph substitutions file              |
|       | `--leet-dict`        | `FILE`   |              | Custom leet substitutions file                   |
|       | `--salt-dict`        | `FILE`   |              | Custom salt dictionary file                      |
|       | `--affix-dict`       | `FILE`   |              | Custom affix dictionary file                     |
|       | `--config`           | `FILE`   |              | Load options from YAML config file               |
| `-l`  | `--list`             |          |              | List all combination types and exit              |
|       | `--preset`           | `NAME`   |              | Apply a named preset (see below)                 |
|       | `--suggest`          |          |              | Analyse input and suggest combinations           |
| `-V`  | `--verbose`          |          |              | Verbose output                                   |
| `-N`  | `--noprogress`       |          |              | Disable progress bar                             |
|       | `--examples`         |          |              | Print usage examples and exit                    |
|       | `--explain`          | `COMBOS` |              | Explain selected combination types               |
|       | `--interactive`      |          |              | Run interactive setup wizard                     |
| `-v`  | `--version`          |          |              | Print version and exit                           |
| `-h`  | `--help`             |          |              | Print help and exit                              |

### Combination types

| Number | Name             | Description                                                                        |
| ------ | ---------------- | ---------------------------------------------------------------------------------- |
| `1`    | Word Mix         | Concatenates permutations of the input words up to `--depth`                       |
| `2`    | Case Alternate   | Generates all case variants (`password`, `PASSWORD`, `Password`, …)                |
| `3`    | Homograph        | Substitutes characters with visually similar equivalents (`a` → `@`, `4`, `α`)     |
| `4`    | Reverser         | Reverses each word (`password` → `drowssap`)                                       |
| `5`    | Saltify          | Prepends and appends entries from the salt dictionary (`123password`, `password!`) |
| `6`    | Leet Speak       | Applies leet substitutions (`e` → `3`, `s` → `5`)                                  |
| `7`    | Separator Insert | Joins word pairs/triples with separator characters (`pass-word`, `pass_word`)      |
| `8`    | Affix            | Prepends and appends common affixes (`!password`, `password2024`)                  |

Run `bin/worcestershire --explain 1 2 3` for a description of specific types.

### Output formats

- `txt` — one word per line (default)
- `json` — one JSON object per line: `{"word":"value"}`
- `hashcat` — one word per line, compatible with hashcat wordlist input

### Encoding and hashing

Pass one of the following to `-e` / `--encode`:

`base64`, `base32`, `url`, `hex`, `md5`, `sha1`, `sha256`, `sha512`

### Presets

| Name                | Combinations | Depth | Min | Max | Encoding | Format | Compress | Limit      |
| ------------------- | ------------ | ----- | --- | --- | -------- | ------ | -------- | ---------- |
| `password-cracking` | 1-8          | 4     | 8   | 32  | —        | txt    | yes      | 10,000,000 |
| `username-enum`     | 2, 4, 7      | 2     | 4   | 20  | —        | txt    | no       | 1,000,000  |
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
combinations:
  - 1
  - 2
  - 3
  - 5
```

```sh
bin/worcestershire -i words.txt --config worcestershire.yml
```

### Rule files

Rule files apply JTR-style single-character transformations to each word. Each line is one rule; a rule is a sequence of commands applied left to right.

| Command | Effect                                      |
| ------- | ------------------------------------------- |
| `l`     | Lowercase                                   |
| `u`     | Uppercase                                   |
| `c`     | Capitalise (first letter upper, rest lower) |
| `r`     | Reverse                                     |
| `d`     | Duplicate (`pass` → `passpass`)             |
| `$`     | Append `!`                                  |
| `^`     | Prepend `!`                                 |

Unknown commands are silently ignored. Each rule produces one additional output word alongside the original.

```
# myrules.rule
l
u
lr
$
```

```sh
bin/worcestershire -i words.txt --rules myrules.rule -o output.lst
```

### Resume

If a run is interrupted (Ctrl-C or `--max-combinations` reached), the state file records the position reached. Pass the same file on the next run to skip already-generated entries.

```sh
# First run — stop early
bin/worcestershire -i words.txt -c 1 2 -o part1.lst --max-combinations 100000 --resume state.json

# Resume — continues from where it stopped
bin/worcestershire -i words.txt -c 1 2 -o part2.lst --resume state.json --force
```

### Custom dictionaries

All built-in dictionaries can be replaced per-run:

| Flag                    | Format                               |
| ----------------------- | ------------------------------------ |
| `--homograph-dict FILE` | One `char->sub1,sub2` entry per line |
| `--leet-dict FILE`      | One `char->sub1,sub2` entry per line |
| `--salt-dict FILE`      | One salt value per line              |
| `--affix-dict FILE`     | One affix value per line             |

### Interactive wizard

Run without arguments or with `--interactive` to step through configuration interactively:

```sh
bin/worcestershire
bin/worcestershire --interactive
```

---

## Shell completion

Completion scripts for bash, zsh, fish, and POSIX sh are in `contrib/`.

| Shell    | File                          | Install                                                    |
| -------- | ----------------------------- | ---------------------------------------------------------- |
| bash     | `contrib/bash_completion.sh`  | Source in `~/.bashrc` or drop in `/etc/bash_completion.d/` |
| zsh      | `contrib/zsh_completion.zsh`  | Place as `_worcestershire` on your `$fpath`                |
| fish     | `contrib/worcestershire.fish` | Place in `~/.config/fish/completions/`                     |
| POSIX sh | `contrib/sh_completion.sh`    | Source in `~/.profile` or any POSIX shell rc file          |

Quick install for bash:

```sh
echo 'source /path/to/worcestershire/contrib/bash_completion.sh' >> ~/.bashrc
source ~/.bashrc
```

Quick install for zsh:

```sh
mkdir -p ~/.zsh/completions
cp contrib/zsh_completion.zsh ~/.zsh/completions/_worcestershire
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc
```

Quick install for fish:

```sh
cp contrib/worcestershire.fish ~/.config/fish/completions/
```

---

## Examples

See `examples/` for ready-to-run scripts:

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
# Run specs
crystal spec

# Run specs with full error traces
crystal spec --error-trace

# Lint (requires ameba)
bin/ameba

# Build debug binary
shards build
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push the branch (`git push origin my-feature`)
5. Open a pull request

Please run `crystal spec` and `bin/ameba` before submitting.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Contributors

- [OkaVatti](https://github.com/OkaVatti) — creator and maintainer (Lily / Oka / AVA)
