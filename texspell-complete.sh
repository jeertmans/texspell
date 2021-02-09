#!/bin/bash

_texspell_completion()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--clean-only
--no-report
--all
--clean
--dict 
--help
--version
--modified
--verbosity"

  local OLDIFS="$IFS"
  local IFS=$'\n'

  if [[ ${cur} == -* ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  fi

  
  #IFS="$OLDIFS"
  #if [[ ${#COMPREPLY[*]} -eq 1 ]]; then #Only one completion
  #  COMPREPLY=( ${COMPREPLY[0]%% "|" *} ) #Remove '|' and everything after
  #  COMPREPLY=( $( compgen -W "0 1" -- ${cur}) )
  #fi

  if [[ ${prev} == "--dict" ]]; then
    COMPREPLY=()
    return 0
  fi

  if [[ ${prev} == "--verbosity" ]]; then
    COMPREPLY=( $(compgen -W "0 1 2" -- ${cur}) )
  fi
  return 0

  
}
#complete -F _texspell_completion texspell
complete -o default -F _texspell_completion texspell


