#!/bin/bash

_texspell_completion()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--clean-only   | Only remove the .diff files
--no-report    | Do not print a report at the end
--all          | Opperate also on hidden files 
--clean        | Remove first the .diff files
--help         | Show the help 
--version      | Installed version of texspell
--modified     | Will only operate on modified files
--verbosity    | Choose the level of verbosity"
  local OLDIFS="$IFS"
  local IFS=$'\n'

  if [[ ${cur} == -* ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  fi

  if [[ ${prev} == "--verbosity" ]]; then
    COMPREPLY=( $(compgen -W "0 1 2" -- ${cur}) )
  fi

  IFS="$OLDIFS"
  if [[ ${#COMPREPLY[*]} -eq 1 ]]; then #Only one completion
    COMPREPLY=( ${COMPREPLY[0]%% "|" *} ) #Remove ' - ' and everything after
  fi
  return 0

  
}
#complete -F _texspell_completion texspell
complete -o default -F _texspell_completion texspell


