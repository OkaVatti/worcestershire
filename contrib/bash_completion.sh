_worcestershire() {
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD - 1]}"

	opts="-w -i -o -c -d -m -M -e -l -V -N -v -h --words --input --output --combination --depth --min --max --encode --list --verbose --noprogress --version --help --format --compress --force --dry-run --quiet --max-combinations --rules --resume --log-file --log-level --buffer-size --no-color --parallel --workers --cache-size --homograph-dict --leet-dict --salt-dict --affix-dict --preset --suggest --examples --explain --interactive"

	if [[ ${cur} == -* ]]; then
		COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
		return 0
	fi

	case "${prev}" in
	-i | --input | -o | --output | --rules | --resume | --log-file | --homograph-dict | --leet-dict | --salt-dict | --affix-dict | --config)
		COMPREPLY=($(compgen -f -- ${cur}))
		;;
	-c | --combination)
		COMPREPLY=($(compgen -W "1 2 3 4 5 6 7 8" -- ${cur}))
		;;
	--format)
		COMPREPLY=($(compgen -W "txt json hashcat" -- ${cur}))
		;;
	--log-level)
		COMPREPLY=($(compgen -W "debug info warn error" -- ${cur}))
		;;
	--preset)
		COMPREPLY=($(compgen -W "password-cracking username-enum quick-test" -- ${cur}))
		;;
	*) ;;
	esac
}
complete -F _worcestershire worcestershire
