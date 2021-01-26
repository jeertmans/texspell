#!/bin/bash

_texspell_completion()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="-o --clean-only --no-report -a --all -c --clean -h --help -v --version"

  if [[ ${cur} == -* ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
  fi

  
}
#complete -F _texspell_completion texspell
complete -o default -F _texspell_completion texspell


