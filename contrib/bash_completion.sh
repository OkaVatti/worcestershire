#!/usr/bin/env bash
# Bash tab-completion for worcestershire.
#
# Installation (choose one):
#   1. Source per-session:
#        source /path/to/contrib/bash_completion.sh
#   2. Per-user permanent:
#        echo 'source /path/to/contrib/bash_completion.sh' >> ~/.bashrc
#   3. System-wide (Debian/Ubuntu/Arch):
#        sudo cp contrib/bash_completion.sh \
#             /etc/bash_completion.d/worcestershire
#   4. System-wide (macOS + Homebrew bash-completion@2):
#        cp contrib/bash_completion.sh \
#           "$(brew --prefix)/etc/bash_completion.d/worcestershire"

_worcestershire() {
	local cur prev words cword
	_init_completion || return

	local flags=(
		-w --words
		-i --input
		-o --output
		-c --combination
		-d --depth
		-m --min
		-M --max
		-e --encode
		--format
		--compress
		--force
		--dry-run
		--quiet
		--max-combinations
		--rules
		--resume
		--log-file
		--log-level
		--buffer-size
		--no-color
		--parallel
		--workers
		--cache-size
		--max-memory
		--homograph-dict
		--leet-dict
		--salt-dict
		--affix-dict
		--config
		-l --list
		--preset
		--suggest
		-V --verbose
		-N --noprogress
		--examples
		--explain
		--interactive
		-v --version
		-h --help
	)

	case "$prev" in
	-i | --input | -o | --output | --rules | --resume | --log-file | \
		--homograph-dict | --leet-dict | --salt-dict | --affix-dict | --config)
		_filedir
		return
		;;
	-e | --encode)
		COMPREPLY=($(compgen -W \
			"base64 base32 url hex md5 sha1 sha256 sha512" \
			-- "$cur"))
		return
		;;
	--format)
		COMPREPLY=($(compgen -W "txt json hashcat" -- "$cur"))
		return
		;;
	--log-level)
		COMPREPLY=($(compgen -W "debug info warn error" -- "$cur"))
		return
		;;
	--preset)
		COMPREPLY=($(compgen -W \
			"password-cracking username-enum quick-test" \
			-- "$cur"))
		return
		;;
	-c | --combination)
		# Multiple values are allowed; complete each token.
		COMPREPLY=($(compgen -W "1 2 3 4 5 6 7 8" -- "$cur"))
		return
		;;
	-d | --depth)
		COMPREPLY=($(compgen -W "2 3 4 5" -- "$cur"))
		return
		;;
	--workers)
		COMPREPLY=($(compgen -W "1 2 4 8 16" -- "$cur"))
		return
		;;
	esac

	if [[ "$cur" == -* ]]; then
		COMPREPLY=($(compgen -W "${flags[*]}" -- "$cur"))
		return
	fi
}

complete -F _worcestershire worcestershire
