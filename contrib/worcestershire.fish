# Fish shell completions for worcestershire.
#
# Installation:
#   cp contrib/worcestershire.fish ~/.config/fish/completions/
#
# Fish automatically loads any file in ~/.config/fish/completions/ whose name
# matches the command.  No sourcing or extra configuration is needed.

# Disable file completion by default; re-enable it per-argument below.
complete -c worcestershire -f

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
complete -c worcestershire -s w -l words \
	-d 'Space-separated words to process' \
	-r

complete -c worcestershire -s i -l input \
	-d 'Input file, one word per line (repeatable)' \
	-r -F

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
complete -c worcestershire -s o -l output \
	-d 'Output file (default: output.lst)' \
	-r -F

complete -c worcestershire -l format \
	-d 'Output format' \
	-r -a 'txt\t"One word per line" json\t"One JSON object per line" hashcat\t"Hashcat-compatible"'

complete -c worcestershire -l compress \
	-d 'Compress output with gzip'

complete -c worcestershire -l force \
	-d 'Overwrite output file without prompting'

complete -c worcestershire -l dry-run \
	-d 'Estimate output size only, do not write'

complete -c worcestershire -l quiet \
	-d 'Suppress all non-essential output'

# ---------------------------------------------------------------------------
# Combination types
# ---------------------------------------------------------------------------
complete -c worcestershire -s c -l combination \
	-d 'Combination types (1-8, space-separated)' \
	-r -a '1\t"Word Mix" 2\t"Case Alternate" 3\t"Homograph" 4\t"Reverser" 5\t"Saltify" 6\t"Leet Speak" 7\t"Separator Insert" 8\t"Affix"'

complete -c worcestershire -s d -l depth \
	-d 'Word mix depth (2-5, default: 3)' \
	-r -a '2 3 4 5'

complete -c worcestershire -s m -l min \
	-d 'Minimum output word length' \
	-r

complete -c worcestershire -s M -l max \
	-d 'Maximum output word length' \
	-r

# ---------------------------------------------------------------------------
# Encoding
# ---------------------------------------------------------------------------
complete -c worcestershire -s e -l encode \
	-d 'Encode/hash each output word' \
	-r -a '
base64\t"Base-64 encode"
base32\t"Base-32 encode"
url\t"URL percent-encode"
hex\t"Hexadecimal encode"
md5\t"MD5 hash"
sha1\t"SHA-1 hash"
sha256\t"SHA-256 hash"
sha512\t"SHA-512 hash"'

# ---------------------------------------------------------------------------
# Advanced
# ---------------------------------------------------------------------------
complete -c worcestershire -l max-combinations \
	-d 'Stop after N combinations' \
	-r

complete -c worcestershire -l rules \
	-d 'JTR-style rule file' \
	-r -F

complete -c worcestershire -l resume \
	-d 'Resume from saved state file' \
	-r -F

complete -c worcestershire -l log-file \
	-d 'Write log messages to file' \
	-r -F

complete -c worcestershire -l log-level \
	-d 'Log level' \
	-r -a 'debug\t"All messages" info\t"Default" warn\t"Warnings and errors" error\t"Errors only"'

complete -c worcestershire -l buffer-size \
	-d 'Output buffer size in bytes (default: 1048576)' \
	-r

complete -c worcestershire -l no-color \
	-d 'Disable ANSI colour output'

complete -c worcestershire -l parallel \
	-d 'Enable multi-threaded generation'

complete -c worcestershire -l workers \
	-d 'Number of concurrent worker fibers (default: 4)' \
	-r -a '1 2 4 8 16'

complete -c worcestershire -l cache-size \
	-d 'Encoding LRU cache size (default: 1000)' \
	-r

complete -c worcestershire -l max-memory \
	-d 'Abort if heap usage exceeds N bytes' \
	-r

# ---------------------------------------------------------------------------
# Custom dictionaries
# ---------------------------------------------------------------------------
complete -c worcestershire -l homograph-dict \
	-d 'Custom homograph substitutions file' \
	-r -F

complete -c worcestershire -l leet-dict \
	-d 'Custom leet substitutions file' \
	-r -F

complete -c worcestershire -l salt-dict \
	-d 'Custom salt dictionary file' \
	-r -F

complete -c worcestershire -l affix-dict \
	-d 'Custom affix dictionary file' \
	-r -F

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
complete -c worcestershire -l config \
	-d 'Load options from YAML config file' \
	-r -F

# ---------------------------------------------------------------------------
# Presets
# ---------------------------------------------------------------------------
complete -c worcestershire -l preset \
	-d 'Apply a named preset' \
	-r -a '
password-cracking\t"All combos, depth 4, length 8-32, compressed, 10M limit"
username-enum\t"Combos 2/4/7, depth 2, length 4-20, 1M limit"
quick-test\t"Combos 1/2, depth 2, base64/json, 1000 limit"'

# ---------------------------------------------------------------------------
# Informational / control
# ---------------------------------------------------------------------------
complete -c worcestershire -s l -l list \
	-d 'List all combination types and exit'

complete -c worcestershire -l suggest \
	-d 'Suggest combinations based on the input words'

complete -c worcestershire -s V -l verbose \
	-d 'Verbose output'

complete -c worcestershire -s N -l noprogress \
	-d 'Disable the progress bar'

complete -c worcestershire -l examples \
	-d 'Print usage examples and exit'

complete -c worcestershire -l explain \
	-d 'Explain selected combination types' \
	-r -a '1 2 3 4 5 6 7 8'

complete -c worcestershire -l interactive \
	-d 'Launch the interactive setup wizard'

complete -c worcestershire -s v -l version \
	-d 'Print version and exit'

complete -c worcestershire -s h -l help \
	-d 'Print help and exit'
