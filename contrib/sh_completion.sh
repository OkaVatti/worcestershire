#!/bin/sh
# POSIX sh tab-completion for worcestershire.
#
# Installation:
#   . /path/to/contrib/sh_completion.sh
#
# This file is intentionally kept POSIX-compliant (no bashisms) so it can be
# sourced by dash, ash, busybox sh, and any other POSIX shell in addition to
# bash and zsh in POSIX mode.

_worcestershire_complete() {
	# $1 = command name (ignored)
	# $2 = current word being completed
	# $3 = previous word

	_wor_cur="$2"
	_wor_prev="$3"

	_wor_flags="\
-w --words \
-i --input \
-o --output \
-c --combination \
-d --depth \
-m --min \
-M --max \
-e --encode \
--format \
--compress \
--force \
--dry-run \
--quiet \
--max-combinations \
--rules \
--resume \
--log-file \
--log-level \
--buffer-size \
--no-color \
--parallel \
--workers \
--cache-size \
--max-memory \
--homograph-dict \
--leet-dict \
--salt-dict \
--affix-dict \
--config \
-l --list \
--preset \
--suggest \
-V --verbose \
-N --noprogress \
--examples \
--explain \
--interactive \
-v --version \
-h --help"

	case "$_wor_prev" in
	-i | --input | -o | --output | --rules | --resume | --log-file | \
		--homograph-dict | --leet-dict | --salt-dict | --affix-dict | --config)
		# Complete file paths.
		COMPREPLY=$(compgen -f -- "$_wor_cur")
		;;
	-e | --encode)
		COMPREPLY=$(compgen -W \
			"base64 base32 url hex md5 sha1 sha256 sha512" \
			-- "$_wor_cur")
		;;
	--format)
		COMPREPLY=$(compgen -W "txt json hashcat" -- "$_wor_cur")
		;;
	--log-level)
		COMPREPLY=$(compgen -W "debug info warn error" -- "$_wor_cur")
		;;
	--preset)
		COMPREPLY=$(compgen -W \
			"password-cracking username-enum quick-test" \
			-- "$_wor_cur")
		;;
	-c | --combination)
		COMPREPLY=$(compgen -W "1 2 3 4 5 6 7 8" -- "$_wor_cur")
		;;
	-d | --depth)
		COMPREPLY=$(compgen -W "2 3 4 5" -- "$_wor_cur")
		;;
	*)
		case "$_wor_cur" in
		-*)
			COMPREPLY=$(compgen -W "$_wor_flags" -- "$_wor_cur")
			;;
		esac
		;;
	esac
}

# Register with whichever completion mechanism is available.
if command -v complete >/dev/null 2>&1; then
	# bash (or zsh with bashcompinit)
	complete -F _worcestershire_complete worcestershire
fi
