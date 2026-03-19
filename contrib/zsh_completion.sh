#compdef worcestershire
# Zsh tab-completion for worcestershire.
#
# Installation (choose one):
#   1. Copy to a directory on $fpath named _worcestershire:
#        mkdir -p ~/.zsh/completions
#        cp contrib/zsh_completion.zsh ~/.zsh/completions/_worcestershire
#        # Add to ~/.zshrc if not already present:
#        echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
#        echo 'autoload -Uz compinit && compinit' >> ~/.zshrc
#   2. With oh-my-zsh, place _worcestershire in
#        ~/.oh-my-zsh/completions/

_worcestershire() {
	local context state state_descr line
	typeset -A opt_args

	local -a encoding_types
	encoding_types=(
		'base64:Base-64 encode each word'
		'base32:Base-32 encode each word'
		'url:URL (percent) encode each word'
		'hex:Hexadecimal encode each word'
		'md5:MD5 hash each word'
		'sha1:SHA-1 hash each word'
		'sha256:SHA-256 hash each word'
		'sha512:SHA-512 hash each word'
	)

	local -a output_formats
	output_formats=(
		'txt:One word per line (default)'
		'json:One JSON object per line'
		'hashcat:Hashcat-compatible wordlist'
	)

	local -a log_levels
	log_levels=(
		'debug:All messages'
		'info:Informational and above (default)'
		'warn:Warnings and errors only'
		'error:Errors only'
	)

	local -a presets
	presets=(
		'password-cracking:All combos, depth 4, length 8-32, compressed, 10M limit'
		'username-enum:Combos 2/4/7, depth 2, length 4-20, 1M limit'
		'quick-test:Combos 1/2, depth 2, base64/json output, 1000 limit'
	)

	local -a combo_types
	combo_types=(
		'1:Word Mix'
		'2:Case Alternate'
		'3:Homograph substitution'
		'4:Reverser'
		'5:Saltify'
		'6:Leet Speak'
		'7:Separator Insert'
		'8:Affix (prefix/suffix)'
	)

	_arguments -C -s \
		'(-w --words)'{-w,--words}'[Space-separated words to process]:words' \
		'*'{-i,--input}'[Input file (repeatable)]:input file:_files' \
		'(-o --output)'{-o,--output}'[Output file]:output file:_files' \
		'(-c --combination)'{-c,--combination}'[Combination types]:combination types (space-separated):->combos' \
		'(-d --depth)'{-d,--depth}'[Word mix depth (2-5)]:depth:(2 3 4 5)' \
		'(-m --min)'{-m,--min}'[Minimum output word length]:minimum length' \
		'(-M --max)'{-M,--max}'[Maximum output word length]:maximum length' \
		'(-e --encode)'{-e,--encode}'[Encode/hash algorithm]:encoding:->encoding' \
		'--format[Output format]:format:->format' \
		'--compress[Compress output with gzip]' \
		'--force[Overwrite output without prompting]' \
		'--dry-run[Estimate output size only]' \
		'--quiet[Suppress non-essential output]' \
		'--max-combinations[Stop after N combinations]:count' \
		'--rules[JTR-style rule file]:rule file:_files' \
		'--resume[Resume state file]:state file:_files' \
		'--log-file[Log file path]:log file:_files' \
		'--log-level[Log level]:level:->loglevel' \
		'--buffer-size[Output buffer size in bytes]:bytes' \
		'--no-color[Disable ANSI colour output]' \
		'--parallel[Enable multi-threaded generation]' \
		'--workers[Number of worker fibers]:workers:(1 2 4 8 16)' \
		'--cache-size[Encoding LRU cache size]:size' \
		'--max-memory[Abort if heap exceeds N bytes]:bytes' \
		'--homograph-dict[Custom homograph dictionary file]:file:_files' \
		'--leet-dict[Custom leet dictionary file]:file:_files' \
		'--salt-dict[Custom salt dictionary file]:file:_files' \
		'--affix-dict[Custom affix dictionary file]:file:_files' \
		'--config[YAML config file]:config file:_files' \
		'(-l --list)'{-l,--list}'[List combination types and exit]' \
		'--preset[Apply named preset]:preset:->preset' \
		'--suggest[Suggest combinations based on input]' \
		'(-V --verbose)'{-V,--verbose}'[Verbose output]' \
		'(-N --noprogress)'{-N,--noprogress}'[Disable progress bar]' \
		'--examples[Print usage examples and exit]' \
		'--explain[Explain combination types]:types' \
		'--interactive[Launch interactive wizard]' \
		'(-v --version)'{-v,--version}'[Print version and exit]' \
		'(-h --help)'{-h,--help}'[Print help and exit]' &&
		return 0

	case "$state" in
	combos)
		_describe 'combination type' combo_types
		;;
	encoding)
		_describe 'encoding' encoding_types
		;;
	format)
		_describe 'output format' output_formats
		;;
	loglevel)
		_describe 'log level' log_levels
		;;
	preset)
		_describe 'preset' presets
		;;
	esac
}

_worcestershire "$@"
