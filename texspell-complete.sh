#!/bin/bash

_texspell()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--clean-only
--no-report
--all
--clean
--config
--dict 
--help
--version
--modified
--verbosity"

  local OLDIFS="$IFS"
  local IFS=$'\n'

  if [[ ${cur} == -* ]]; then
    COMPLET=${opts}
  fi

  
  #IFS="$OLDIFS"
  #if [[ ${#COMPREPLY[*]} -eq 1 ]]; then #Only one completion
  #  COMPREPLY=( ${COMPREPLY[0]%% "|" *} ) #Remove '|' and everything after
  #  COMPREPLY=( $( compgen -W "0 1" -- ${cur}) )
  #fi

  if [[ ${prev} == "--dict" ]]; then
    echo ""
  fi

  if [[ ${prev} == "--config" ]]; then
    echo ""
  fi

  if [[ ${prev} == "--verbosity" ]]; then
    echo "0 1 2"
  fi

  echo "$COMPLET"

  
}

_texspell_bash() {
  local cur
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W '$( _texspell )' -- $cur) )
}


complete -o default -F _texspell_bash texspell
