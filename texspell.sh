#! /bin/bash

#############
# Constants #
#############

# Colors
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

DIFF_EXT=".diff" # Might be changed or choosed by user later... ?
TEX_EXT=".tex"
DIC_EXT=".dic"


DOC="
\ttexspell -- Command line spell-checker tool for TeX documents\n
\n
Options:\n
-h, --help: get this help\n
-s, --single-file: Check only the file and not the project
-c, --clean: Remove all .diff in the . directiory and sub-directories\n
    --config [FILE]: select a config file to use
-d, --dict [FILE]: Create a dict from FILE
-o, --clean-only: Do not generate the ${DIFF_EXT}\n
-m, --modified: Will report only the modified .diff (cannot the .diff)\n
--no-report: Do not produce a report\n
-v, --version: get version number\n
\n"

##################
# Default values #
##################

ignore="colors.tex" # Good for testing but should be removed :)
CLEAN=0 #Remove or not diff files
SPELL=1 #Create or not diff files
VERBOSITY=1 # Level of verbosity
REPORT=1 # Produce a report or not
ONLY_MODIFIED=0 # report (and print only the modified files
CHECK_HIDDEN=0 #Check or not (spell/clean) files in hidden dir/files
SRC="." # SRC to check
SRCISFILE=0 # Is SRC a file
TEMP_DIR=""
MAKE_DICT=0
LIST_DICT=""
DICT="dict_texspell"
N_WORD_KEPT=3

REPORT_FILE="report_texspell"
PATH_CONFIG="$HOME/.config/texspell.cfg"
CHECK_PROJECT=1

# Config
typeset -A CONFIG
CONFIG=(
  [HOST]="127.0.0.1"
  [PORT]="8081"
  [LANGUAGETOOLS]="TRUE"
  [SPELLCHECK]="LANGUAGETOOLS"
)


##################
# REGEX PATTERNS #
##################

# Pattern to be used with detex -1 option
# Will catch:
#   \1 - prefix (filename + lineno)
#   \2 - filename
#   \3 - linenumber
#   \4 - line content (possibly empty)
#DETEX_1_PATTERN="((.*.tex):([0-9]+):)(.*)"

#################
# Flags handler #
#################
while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo -e "$DOC"
      exit 0
      ;;
    -v|--version)
      echo "Version: 2"
      shift
      ;;
    -s|--single_file)
      CHECK_PROJECT=0
      shift
      ;;
    -c|--clean)
      CLEAN=1
      shift
      ;;
    -o|--clean-only)
      CLEAN=1
      SPELL=0
      shift
      ;;
    --no-report)
      REPORT=0
      shift
      ;;
    --verbosity)
      VERBOSITY=$2
      shift
      shift
      ;;
    -a|--all)
      CHECK_HIDDEN=1 
      shift
      ;;
    -m|--modified)
      ONLY_MODIFIED=1
      shift
      ;;
    -d|--dict)
      if [ -f "$2" ]; then
        MAKE_DICT=1
        LIST_DICT="$2"
      else
        echo "Dictionary \"$2\" is not a file"
        exit 1
      fi
      shift
      shift
      ;;
    --config)
      if [ -f "$2" ]; then
        PATH_CONFIG="$2"
      else
        echo "\"$2\" is not a config file"
        exit 1
      fi
      shift
      shift
      ;;
    *)
      if [ -f "$1" ]; then
        SRCISFILE=1
        SRC=$1
        shift
      elif [ -d "$1" ]; then
        SRCISFILE=0
        SRC=$1
        shift
      else
      echo "Last argument should be either a file or a directoy: ""${1}"
      exit 1
      fi
      ;;
  esac
done

#########################
# Function declarations #
#########################

# Find files
# 1 - Source file or directory
# 2 - Extention of file, ex.: ".tex", ".diff"
# 3 - Binary variable (0 or 1) to say if hidden files must be included
# + - All other files or pattern (non case-sensitive) that must be excluded
#
# R - All the files matching conditons
function find_files {
  local SRC=$1
  local EXT=$2
  local HID=$3
  local IGN=""
  while test $# -gt 3; do
    IGN="${IGN} ! -iname $4"
    shift
  done
  if [ "$HID" -eq 1 ]; then
    find "$SRC" -type f -iname "*${EXT}" "$IGN"
  else
    find "$SRC" -type f -iname "*${EXT}" "$IGN" -not -path "*/\.*"
  fi
}

# Remove files
# 1 - List of files
#
# R - Nothing
function remove_files {
  local FILES=$1
  xargs -n 1 -r rm "$FILES"
}

# Remove colors from input
# https://stackoverflow.com/questions/17998978/removing-colors-from-output
# 1 - Input
#
# R - The input with colors removed
function remove_colors {
  local IN=$1
  sed -E "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" "$IN"
}

# Substitute regex pattern
# 1 - Input
# 2 - Search pattern, ex.: "([a-zA-Z])"
# 3 - Sub. pattern, ex.: "_\1_" to add "_" around matching patterns
#
# R - The input with substituted patterns
function regex_sub {
  local STR=$1
  local PAT=$2
  local SUB=$3
  echo "${STR}" | sed -E "s/${PAT}/${SUB}/g"
}

# Substitute regex pattern in file (in-place)
# 1 - Input file
# 2 - Search pattern, ex.: "([a-zA-Z])"
# 3 - Sub. pattern, ex.: "_\1_" to add "_" around matching patterns
#
# R - Nothing
function regex_sub_file {
  local FILE=$1
  local PAT=$2
  local SUB=$3
  sed -i -E "s/${PAT}/${SUB}/g" "$FILE"
}

# Write into a file the errors, their line number and the correction suggestions
# 1 - Input file
# 2 - Output file
#
# R - Nothing
function errors_and_suggestions {
  local IN=$1
  local OUT=$2

  # Run hunspell, discarding lines with no error (*)
  hunspell -a -t -i utf-8 -d en_US,$DICT <"$IN" | grep -v '[\*]' > "$OUT"
  # Clean the first line of the file containing a header from Ispell
  sed -i '1d' "$OUT"
  # Remove extra linebreaks
  sed -i '/^$/N;/^\n$/D' "$OUT"
  
  MATCH="&\s(\S+)\s([0-9]+)\s([0-9]+):\s(.+)"
  SUBS="V\3: \1 => (\2) \4"

  regex_sub_file "$OUT" "${MATCH}" "${SUBS}" 
}

# Write into a file the lines where errors occur
# 1 - Input file
# 2 - Ouput file
#
# R - Nothing
function lines_with_errors {
  local IN=$1
  local OUT=$2
  hunspell -L -t -i utf-8 -d en_US,$DICT <"$IN" > "$OUT"
}

# Returns a given line from a file
# 1 - The file
# 2 - The line number
#
# R - The Ith line
function ith_line_file {
  local FILE=$1
  local I=$2
  sed "${I}q;d" "$FILE"
}

# Return the line number of the first line matching a given string
# 1 - The search string
# 2 - The file
#
# R - The line number
function first_match_lineno_file {
  local MATCH=$1
  local FILE=$2
  #echo $(echo $MATCH | grep -Fx -n -f - $FILE | cut -f1 -d:)
  grep -F -o -m 1 -h -n -e "$(strip_leading_spaces "${MATCH}")" "$FILE" | cut -f1 -d:
}

# Will update $DICT with respect to $1
# 1 - File with the list of word into the dict
#
# R - Nothing
function create_dict {
  SORTED=$(< "$1" sort | uniq) 
  echo "$SORTED" >&2
  echo "$SORTED" | wc -l > $DICT$DIC_EXT
  echo "$SORTED" >> $DICT$DIC_EXT
}

# Remove all the space from the first argument and output it
# 1 - String to clean
#
# R - String cleaned
function strip_leading_spaces {
  echo "$1" | sed "s/ *$//g"
}

# Replace all \ by \\
# 1 - String to replace
#
# R - Replaced string
function replace_backslash_by_double {
  echo "${1//\\/\\\\\\}"
  #echo "$1" | sed "s/\\/\\\\/g'
}

# Clean string for echo -e
# 1 - String to clean
#
# R - String cleaned
function clean_for_echo {
  replace_backslash_by_double "$(strip_leading_spaces "$1")"
}

# Keep only x first words
# 1 - String
# 2 - Number of words
#
# R - X first words
function keep_x_first_words {
  echo "$1" | tr ' ' '\n' | head -"${2}" | xargs -n"${2}"
}

# Keep only x last words
# 1 - String
# 2 - Number of words
#
# R - X last words
function keep_x_last_words {
  echo "$1" | tr ' ' '\n' | tail -"${2}" | xargs -n"${2}"
}

# Create a new tmp file 
# 1 filename
#
# R - path tho file
function create_file {
  mktemp -p "${TEMP_DIR}" "${1}_XXXXX.tmp"
}

# Reduce string to the first X words. It will also add [...] if word are removed
# 1 - String to operate to
# 2 - Number of words to keep
#
# R - String with less words
function reduce_string_size_first {
  local STR=$1
  local LEN=$2

  local OUT
  OUT=$(keep_x_first_words "$STR" "$LEN")
  if [ "$(echo "$OUT" | wc -w)" -eq "$(echo "$STR" | wc -w)" ]; then
    echo "$STR"
  else
    local DEB=""
    local END=""
    if [ "${STR: -1}" == " " ]; then
      END=" "
    fi
    if [ "${STR: 0}" == " " ]; then
      DEB=" "
    fi
    echo "$DEB$OUT [...]$END"
  fi
}

# Reduce string to the last X words. It will also add [...] if word are removed
# 1 - String to operate to
# 2 - Number of words to keep
#
# R - String with less words
function reduce_string_size_last {
  local STR=$1
  local LEN=$2

  local OUT
  OUT=$(keep_x_last_words "$STR" "$LEN")
  if [ "$(echo "$OUT" | wc -w)" -eq "$(echo "$STR" | wc -w)" ]; then
    echo "$STR"
  else
    local DEB=""
    local END=""
    if [ "${STR: -1}" == " " ]; then
      END=" "
    fi
    if [ "${STR:0:1}" == " " ]; then
      DEB=" "
    fi
    echo "${DEB}[...] $OUT$END"
  fi
}

# Reduce string to the last and first X words. It will also add [...] if word are removed
# 1 - String to operate to
# 2 - Number of words to keep
#
# R - String with less words
function reduce_string_size {
  local STR=$1
  local LEN=$2

  local FIRST
  FIRST=$(keep_x_first_words "$STR" "$LEN")
  local LAST
  FIRST=$(keep_x_last_words "$STR" "$LEN")
  if [ $(($(echo "$FIRST" | wc -w) + $(echo "$LAST" | wc -w))) -lt "$(echo "$STR" | wc -w)" ]; then
    local OUT="$FIRST [...] $LAST"
    local DEB=""
    local END=""
    if [ "${STR: -1}" == " " ]; then
      END=" "
    fi
    if [ "${STR:0:1}" == " " ]; then
      DEB=" "
    fi
    echo "$DEB$OUT$END"
  else
    echo "$STR"
  fi
}

# Report all error of a file
# 1 - File to be reported
#
# R - "TMP_FILE_DIFF" "TMP_FILE_STDOUT" "L_ERRORS" "L_UNKNOWN_WORDS"
function report_file {
  local FILE=$1
  local FILENAME
  FILENAME=$(basename "$FILE")

  local L_ERRORS=0
  local L_UNKNOWN_WORDS=0

  # Generate TMP 1
  local TMP_FILE_1
  TMP_FILE_1=$(mktemp -p "${TEMP_DIR}" "${FILENAME}1_XXXXX.tmp")
  errors_and_suggestions "$FILE" "$TMP_FILE_1"

  
  # Generate TMP 2
  local TMP_FILE_2
  TMP_FILE_2=$(mktemp -p "${TEMP_DIR}" "${FILENAME}2_XXXXX.tmp")
  lines_with_errors "$FILE" "$TMP_FILE_2" 

  local TMP_FILE_DIFF
  TMP_FILE_DIFF=$(mktemp -p "${TEMP_DIR}" "${FILENAME}3_XXXXX.tmp")
  
  local TMP_FILE_STDOUT
  TMP_FILE_STDOUT=$(mktemp -p "${TEMP_DIR}" "${FILENAME}5_XXXXX.tmp")

  # Count the # of lines (errors) in file
  local N_LINES
  N_LINES=$(wc -l "$TMP_FILE_1" | awk '{ print $1 }') 
  
  if [ "$N_LINES" -eq 1 ]; then 
    if [[ $(cat "$TMP_FILE_1") == "" ]]; then
      N_LINES=0
      cat /dev/null > "$TMP_FILE_1"
    fi
  fi

  if [ $N_LINES -eq 0 ]; then
    if [ "$VERBOSITY" -ge 1 ]; then
      echo "$FILE" " contains no error" >> "$TMP_FILE_STDOUT"
    fi

  else
    #local DIFF_FILE="${FILE}${DIFF_EXT}"
    echo "Created by texspell">> "$TMP_FILE_DIFF"

    j=0
    k=-1
    POS=0
    COLORIZED_LINE=""
    COLORIZED_ERRORS=""
    for (( i=1; i <= N_LINES ; i++ ))
    do
      SUGGESTIONS=$(ith_line_file "$TMP_FILE_1" "$i")

      if [ -z "${SUGGESTIONS}" ]; then
        j=$((j+1))
      else
        if [ $j -gt $k ]; then

          if [ "$VERBOSITY" -ge 2 ] && [ -n "${COLORIZED_ERRORS}" ]; then
            if [ "$VERBOSITY" -lt 3 ]; then
              COLORIZED_LINE+=$(reduce_string_size_first "${ERRORNOUS_LINE:$POS:${#ERRORNOUS_LINE}}" $N_WORD_KEPT)
            else
              COLORIZED_LINE+="${ERRORNOUS_LINE:$POS:${#ERRORNOUS_LINE}}"
            fi
            COLORIZED_LINE=$(strip_leading_spaces "$COLORIZED_LINE")
            {
              echo -e "$COLORIZED_LINE"
              echo -e "$COLORIZED_ERRORS"
              echo "-----"
            } >> "$TMP_FILE_STDOUT"
            COLORIZED_LINE=""
            COLORIZED_ERRORS=""
            POS=0
          fi

          ERRORNOUS_LINE="$(ith_line_file "$TMP_FILE_2" $j)"
          LINE_NO=$(first_match_lineno_file "${ERRORNOUS_LINE}" "$FILE")

          {
            echo "----"
            echo "In line ${LINE_NO}:"
            echo "$ERRORNOUS_LINE"
          } >> "$TMP_FILE_DIFF"
          k=$j
        fi
        
        echo "$SUGGESTIONS" >> "$TMP_FILE_DIFF"

        if [ "$VERBOSITY" -ge 2 ]; then
          MATCH="(V([0-9]+):\s)(\S+)(\s=>\s)(.+)"
          SUBS1="\1\\${RED}\3\\${NC}\4\\${GREEN}\5\\${NC}"
          SUBS2="\2"
          SUBS3="\3"
          V_POSITION=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS2}")
          ERRORNOUS_WORD=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS3}")
          COLORIZED_SUGG=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS1}")
          if [ -z "$COLORIZED_ERRORS" ]; then
            COLORIZED_ERRORS="${COLORIZED_SUGG}"
          else
            COLORIZED_ERRORS+="\n${COLORIZED_SUGG}"
          fi
          LENGTH=$((V_POSITION-POS))
          PREV_NC=${ERRORNOUS_LINE:$POS:$LENGTH}
          PREV_NC=$(replace_backslash_by_double "${PREV_NC}")
          if [ "$VERBOSITY" -lt 3 ]; then
            if [ $POS -eq 0 ]; then 
              PREV_NC=$(reduce_string_size_last "$PREV_NC" $N_WORD_KEPT)
            else
              PREV_NC=$(reduce_string_size "$PREV_NC" $N_WORD_KEPT)
            fi
          fi
          COLORIZED_LINE+="${PREV_NC}${RED}${ERRORNOUS_WORD}${NC}"
          POS=$((V_POSITION+${#ERRORNOUS_WORD}))
        fi
      fi
    done
    # Print last line
    if [ "$VERBOSITY" -ge 2 ] && [ -n "${COLORIZED_ERRORS}" ]; then
      if [ "$VERBOSITY" -lt 3 ]; then
        COLORIZED_LINE+=$(reduce_string_size_first "${ERRORNOUS_LINE:$POS:${#ERRORNOUS_LINE}}" $N_WORD_KEPT)
      else
        COLORIZED_LINE+="${ERRORNOUS_LINE:$POS:${#ERRORNOUS_LINE}}"
      fi
      COLORIZED_LINE=$(strip_leading_spaces "$COLORIZED_LINE")

      echo -e "$COLORIZED_LINE" >> "$TMP_FILE_STDOUT"
      echo -e "$COLORIZED_ERRORS" >> "$TMP_FILE_STDOUT"
    fi

    
    L_ERRORS=$(($(grep -c "[=>]" "$TMP_FILE_1")))
    L_UNKNOWN_WORDS=$(($(grep -c '[\#]' "$TMP_FILE_1")))
    sed -i "2iNumber of errors: $L_ERRORS" "$TMP_FILE_DIFF"
    sed -i "3iNumber of unknown words: $L_UNKNOWN_WORDS" "$TMP_FILE_DIFF"
    # Shasum on file with errors
    local SHASUM
    SHASUM=$(sha256sum "$TMP_FILE_2")
    sed -i "2iDate:  $(date)" "$TMP_FILE_DIFF"
    sed -i "5iShasum: $SHASUM" "$TMP_FILE_DIFF"

  fi
  echo "$TMP_FILE_DIFF $TMP_FILE_STDOUT" $L_ERRORS $L_UNKNOWN_WORDS
}

# Before is old function

# Load config file into config array
# It will only override config variables that are present in the files
# and currently exist
# 1 - Path to any config file
#
# R - Nothing
function load_config {
  local CONF_FILE=$1
  if [ -f "$1" ]; then
    for KEY in "${!CONFIG[@]}"; do
      # Only select last matching pattern in config file
      VALUE=$(sed -n -E "s/^\s*${KEY}\s*=\s*(.*)\s*$/\1/p" "$CONF_FILE" | tail -n -1)
      if [ -n "$VALUE" ]; then
        CONFIG[$KEY]="$VALUE"
      fi
    done
  fi
}


# Function to raw urlencode
# 1 - string to urlencode
#
# R - string urlencoded
function rawurlencode {
  # We need this function because curl --data-encoded not work on \n
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
}


# Simple function to make request to languageTool
# 1 - The text to check with languageTool
#
# R - The response of languagetool
function request_languagetool
{
  curl -s --data "language=en-US&data=$(rawurlencode "$1")" http://"${CONFIG[HOST]}":"${CONFIG[PORT]}"/v2/check
}

# Will compute the number of \n a input text with a limit of chars to check
# 1 - The text to check
# 2 - The limit of char
# 
# R - The number of \n
function get_number_new_line {
  echo "$1" | cut -c1-"$2" | grep -o '\n' | wc -l
}

# Will compute the chars on the $2 lines of $1. New lines are made with \n
# 1 - SRC
# 3 - C
#
# R - Number of char
function get_nb_char_up_to_line {
  local CUTTED
  CUTTED=$(echo "$1" | grep -o '.*\n')
  echo ${#CUTTED}
}

# A function to cut the differents errors and process them
# 1 - The string representing a json (after matches from the response of languageTool
# 2 - the Path to write the errors 
# 3 - Offset of number of line
# 4 - Path to true plaintext
#
# R - Nothing
function split_and_process_languagetool {
  local IN=$1
  local OUT=$2
  local OFFSET=$3
  local SRC=$4

  local ERRORS

  # Cut the response of the servor the aves the errors
  ERRORS=$(echo "$IN" | grep -o 'matches.*' | cut -f2- -d:)
  ERRORS=${ERRORS%?}

  # No errors
  if [[ $ERRORS == "[]" ]]; then
    return
  fi 
    
  #Variable declaration
  local LINENUMBER
  local OLDLINENUMBER
  local CUTTED_TEXT
  local delimiter
  local s
  local ERROR
  local ERR
  local LEN_ERR
  local POS_ERR
  local SENTENCE
  local REPLS
  local NB_REPL
  local REPL
  local i 
  OLDLINENUMBER=-1

  # Split each correction 
  delimiter="message"
  s=$ERRORS$delimiter
  while [[ $s ]]; do
    ERR=( "${s%%"$delimiter"*}" );
    ERROR=${ERR[0]} # To please linter

    # Remove first elem from the array
    if [[ $ERROR == "[{\"" ]]; then
      s=${s#*"$delimiter"};
      ERR=( "${s%%"$delimiter"*}" );
      ERROR=${ERR[0]} # To please linter
    fi

    # Fetch position, length and sentence of the error
    POS_ERR=$(echo "$ERROR" | grep -Eo 'offset":[[:digit:]]+' | head -1 | grep -Eo '[[:digit:]]+')
    LEN_ERR=$(echo "$ERROR" | grep -Eo 'length":[[:digit:]]+' | head -1 | grep -Eo '[[:digit:]]+')
    SENTENCE=$(echo "$ERROR" | grep -Eo 'sentence":".*' | grep -Eo '.*","type' )
    
    # Clean sentence and fetch line number
    SENTENCE=${SENTENCE:11:-7}
    LINENUMBER=$(first_match_lineno_file "$SENTENCE" "$SRC")
    LINENUMBER=$((LINENUMBER - OFFSET))

    # Get the number of char beffore
    if [[ $LINENUMBER -ge 1 ]]; then
        CUTTED_TEXT=$(head -$((LINENUMBER-1)) "$SRC" | sed -e "1,$OFFSET"d | wc -c)
    fi

    # Update the position to get position in the line
    POS_ERR=$((POS_ERR - 4*(LINENUMBER -1) -CUTTED_TEXT -1))

    # If we have a new line 
    if [ "$LINENUMBER" != "$OLDLINENUMBER" ]; then
      echo "" >> "$OUT"
      OLDLINENUMBER=$LINENUMBER
      LINENUMBER=$((LINENUMBER + OFFSET))
      echo "${LINENUMBER}" >> "$OUT"
    fi
    NB_REPL=0
    REPL=""

    # Fetch the number of propositions and each propositions
    REPLS=$(echo "$ERROR" | grep -o 'replacements":.*' | cut -f2- -d '[' | cut -f1 -d ']')
    NB_REPL=$(echo "$REPLS" | grep -o '{' | wc -l)
    IFS='{'
    read -ra REPL_TAB <<< "$REPLS"
    for i in "${REPL_TAB[@]}"; do
      REPL+=$(echo "$i" | sed 's/"//g' | cut -f2 -d':'| cut -f1 -d'}' | cut -f1 -d',')
      REPL+="|"
    done

    # Fetch the message
    local MSG
    MSG=$(echo "$ERROR" | grep -o '.*","shortMessage' | sed 's/":"//' | sed 's/","shortMessage//')

    # Output the message
    echo "$POS_ERR|$LEN_ERR|$MSG|$NB_REPL$REPL" >> "$OUT"

    # Go to the next error 
    s=${s#*"$delimiter"};
  done;
}

##################
# Texfile parser #
##################
# 1 - SRC of the project to parse
# 2 - Path to a tmp file with the tex parsed into a plain text
# 3 - Path to a tmp file with the correspondance between tex and plain tex
function tex_parser_opendetex {
  local SRC=$1
  local PLAINTEX=$2
  local MATCHER=$3
  if [ "$CHECK_PROJECT" == 0 ]; then
    detex -n "$SRC" > "$PLAINTEX"
    detex -n -1 "$SRC" | cut -f1,2 -d':' > "$MATCHER"
  else
    detex "$SRC" > "$PLAINTEX"
    detex -1 "$SRC" | cut -f1,2 -d':' > "$MATCHER"
  fi
}

##################
# Spell checker #
##################
# Function that will provide a list of error of a plaintext file
# 1 - Path to a plaintex file to correct
# 2 - Path to a tmp file with
#   * Line of error
#   * Offset and range of the error
#   * Message of error
#   * Number of propositions
#   * Each proposition
# Each element is separated with | 

function spell_checker_hunspell {
  local IN=$1
  local OUT=$2
  local FILE=$1
  local FILE_ERROR_AND_SUGG
  local FILE_LINES_ERROR
  local N_LINES
  
  # Create files and get the errors
  FILE_ERROR_AND_SUGG=$(create_file "errors_and_suggestions")
  FILE_LINES_ERROR=$(create_file "lines_with_errors")
  errors_and_suggestions "$IN" "$FILE_ERROR_AND_SUGG"
  lines_with_errors "$IN" "$FILE_LINES_ERROR" 

  N_LINES=$(wc -l "$FILE_ERROR_AND_SUGG" | awk '{ print $1 }') 
  
  # If the file contain only an empty string -> no error
  if [ "$N_LINES" -eq 1 ]; then 
    if [[ $(cat "$FILE_ERROR_AND_SUGG") == "" ]]; then
      N_LINES=0
      cat /dev/null > "$OUT"
    fi
  fi

  local j
  local k
  local POS
  local SUGGESTIONS

  # No errors
  if [ $N_LINES -eq 0 ]; then
    return  
  else
    j=0
    k=-1
    POS=0
    for (( i=1; i < N_LINES ; i++ ))
    do
      # Fetch the suggestions
      SUGGESTIONS=$(ith_line_file "$FILE_ERROR_AND_SUGG" "$i")

      # If suggestion is empty -> other line in the plaintex file
      if [ -z "${SUGGESTIONS}" ]; then
        j=$((j+1))
      else
        # For the first error of each errored lines
        if [ $j -gt $k ]; then
          ERRORNOUS_LINE="$(ith_line_file "$FILE_LINES_ERROR" $j)"
          LINE_NO=$(first_match_lineno_file "${ERRORNOUS_LINE}" "$IN")

          echo "" >> "$OUT"
          echo "${LINE_NO}" >> "$OUT"
          k=$j
        fi

        #  V type of error
        if [[ ${SUGGESTIONS:0:1} == "V" ]]; then
          # Split with regex
          MATCH="(V([0-9]+):\s)(\S+)(\s=>\s)(.+)"
          MATCH_N_PROP="(([0-9]+))"
          MATCH_PROPS="(,\s)"
          SUBS2="\2"
          SUBS3="\3"
        
          V_POSITION=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS2}")
          ERRORNOUS_WORD=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "${SUBS3}")
          ERRORNOUS=$(regex_sub "${SUGGESTIONS}" "${MATCH}" "\5")
          NUMBER_PROP=$(echo "$ERRORNOUS" | grep -P "$MATCH_N_PROP" -o)
          PROPS=$(regex_sub "${ERRORNOUS}" "${MATCH_PROPS}" "|" | cut -f2- -d ' ')
          echo "$V_POSITION|${#ERRORNOUS_WORD}|Word not in the dict|$NUMBER_PROP|$PROPS|" >> "$OUT"

        # # type of error
        elif [[ ${SUGGESTIONS:0:1} == "#" ]]; then
          # split with regex

          WORD=$(echo "$SUGGESTIONS" | cut -f2 -d ' ')
          V_POSITION=$(echo "$SUGGESTIONS" | cut -f3 -d ' ')
          echo "$V_POSITION|${#WORD}|No match for the word|0|" >> "$OUT"
        fi
      fi
    done
  fi

  # Remove last line
  sed -i '1,1d' "$OUT"
}

function spell_checker_languagetool {
  local IN=$1
  local OUT=$2
  local N_LINES
  local LINE
  local CHARS_TO_CHECK
  local SIZE_CHARS
  local SIZE_CHARS_LINE
  local OFFSET

  # Init
  N_LINES=$(wc -l "$IN" | awk '{ print $1 }') 
  CHARS_TO_CHECK='{"annotation":['
  SIZE_CHARS=0
  SIZE_CHARS_LINE=0
  OFFSET=0
  
  for (( i=1; i <= N_LINES ; i++ ))
  do
    LINE=$(ith_line_file "$IN" "$i")
    SIZE_CHARS_LINE=${#LINE}

    # Limit by languageTool
    if [[ $((SIZE_CHARS_LINE + SIZE_CHARS)) -le 9500 ]]; then

      # Add it to tmp chars
      SIZE_CHARS=$((SIZE_CHARS + SIZE_CHARS_LINE))
      CHARS_TO_CHECK+='{"text":"'
      CHARS_TO_CHECK+="$LINE"
      CHARS_TO_CHECK+='"},{"markup": "<br/>", "interpretAs": "\n\n"},'
    else
      # Finish the json
      CHARS_TO_CHECK=${CHARS_TO_CHECK::-1}
      CHARS_TO_CHECK+="]}"
      
      # Do the correction
      RES=$(request_languagetool "$CHARS_TO_CHECK")
      split_and_process_languagetool "$RES" "$OUT" "$OFFSET" "$IN"
      
      # Start new correction
      OFFSET=$i
      CHARS_TO_CHECK='{"annotation":[ {"text": "'
      CHARS_TO_CHECK+="$LINE"
      CHARS_TO_CHECK+='"},'
      SIZE_CHARS=${#CHARS_TO_CHECK}
    fi
  done

  # last correction 
  CHARS_TO_CHECK=${CHARS_TO_CHECK::-1}
  CHARS_TO_CHECK+="]}"
  RES="$(request_languagetool "$CHARS_TO_CHECK")"
  split_and_process_languagetool "$RES" "$OUT" "$OFFSET" "$IN"

  # Remove first line
  sed -i -e 1,1d "$OUT"

}

##############
# Aggregator #
##############
# The output of the function will be implementation dependant
# 1 - Path to a file with the errors with the format of the spell checker
# 2 - Path to a file to which make the correspondance between the tex project and the plaintext
# 3 - Path to the plaintext file
# 
# R - 

# Will output the sorted errors by files and line nubmer.
# The output used is STDOUT and will use a colored output
function aggregator_sdtout {
  local ERR_FILE=$1
  local MATCH_FILE=$2
  local PLAINTEXT_FILE=$3
  local SORTED_FILE
  SORTED_FILE=$(create_file "sorted")

  local NEW_ERROR
  local N_LINES
  local LINE_MATCHER
  local TMP_LINE
  local NB_ERROR
  NEW_ERROR=1

  # Make the match between the error file/input file
  N_LINES=$(wc -l "$ERR_FILE" | awk '{ print $1 }') 
  for (( i=1; i <= N_LINES ; i++ ))
  do
    LINE=$(ith_line_file "$ERR_FILE" "$i")
    if [ $NEW_ERROR -eq 1 ]; then
      NEW_ERROR=0
      NB_ERROR=0
      LINE_MATCHER=$(ith_line_file "$MATCH_FILE" "$LINE")
      TMP_LINE="${LINE_MATCHER/:/|}|$i"
      
    elif [[ $LINE == "" ]]; then
      TMP_LINE="$TMP_LINE|$NB_ERROR"
      echo "$TMP_LINE" >> "$SORTED_FILE"
      NEW_ERROR=1
    else
      NB_ERROR=$((NB_ERROR + 1))
    fi
  done

  # Sort the error by file 
  local SORTED_FILE_OUTPUT
  SORTED_FILE_OUTPUT=$(create_file "sorted_output")
  sort "$SORTED_FILE" > "$SORTED_FILE_OUTPUT"

  local OLD_FILENAME
  local FILENAME
  OLD_FILENAME=""

  local LINENUMBER
  
  local PLAINTEXT_LINE
  local PLAINTEXT_NLINE
  local ERRORED_LINE
  local ERRORTEXT_NLINE
  local SRCTEXT_NLINE
  local NB_ERRORS

  local OFFSET
  local LENGTH
  local MSG
  local NB_PROP
  local PROP
  
  # For each errored line
  N_LINES=$(wc -l "$SORTED_FILE_OUTPUT" | awk '{ print $1 }') 
  for (( i=1; i <= N_LINES ; i++ ))
  do
    LINE=$(ith_line_file "$SORTED_FILE_OUTPUT" "$i")
    FILENAME=$(echo "$LINE" | cut  -f1 -d "|" )

    # If we are on a new filename
    if [[ "$OLD_FILENAME" != "$FILENAME" ]]; then
      OLD_FILENAME="$FILENAME"
      echo "" >&2
      echo "$FILENAME" >&2
      echo "========" >&2
    fi

    # Fetch the different line
    SRCTEXT_NLINE=$(echo "$LINE" | cut  -f2 -d "|" )
    ERRORTEXT_NLINE=$(echo "$LINE" | cut  -f3 -d "|" )
    NB_ERRORS=$(echo "$LINE" | cut  -f4 -d "|" )
    PLAINTEXT_NLINE=$(ith_line_file "$ERR_FILE" "$ERRORTEXT_NLINE")
    PLAINTEXT_LINE=$(ith_line_file "$PLAINTEXT_FILE" "$PLAINTEXT_NLINE")
    echo "At line $SRCTEXT_NLINE :" >&2
    
    # Error coloring
    for ((j="$ERRORTEXT_NLINE" + "$NB_ERRORS"; j >= "$ERRORTEXT_NLINE" +1; j--))
    do
      ERRORED_LINE=$(ith_line_file "$ERR_FILE" "$j")
      OFFSET=$(echo "$ERRORED_LINE" | cut  -f1 -d "|" )
      LENGTH=$(echo "$ERRORED_LINE" | cut  -f2 -d "|" )
      PLAINTEXT_LINE="${PLAINTEXT_LINE:0:OFFSET}$RED${PLAINTEXT_LINE:$OFFSET:$LENGTH}$NC${PLAINTEXT_LINE:$OFFSET+$LENGTH}"
    done
    echo -e "$PLAINTEXT_LINE" >&2
    
    #Output of each errors
    for ((j="$ERRORTEXT_NLINE" +1; j <= "$ERRORTEXT_NLINE" + "$NB_ERRORS"; j++))
    do
      ERRORED_LINE=$(ith_line_file "$ERR_FILE" "$j")
      OFFSET=$(echo "$ERRORED_LINE" | cut  -f1 -d "|" )
      LENGTH=$(echo "$ERRORED_LINE" | cut  -f2 -d "|" )
      MSG=$(echo "$ERRORED_LINE" | cut  -f3 -d "|" )
      NB_PROP=$(echo "$ERRORED_LINE" | cut  -f4 -d "|" )
      echo "+ O: $OFFSET L: $LENGTH  $MSG" >&2
      for ((k = 5; k < 5 + "$NB_PROP"; k++))
      do
        PROP=$(echo "$ERRORED_LINE" | cut  -f"$k" -d "|" )
        echo "  + $PROP" >&2
      done

    done

    echo "" >&2
  done
}


####################
# Script execution #
####################

# Check if the project file is specified
if [ -d "$SRC" ]; then
  >&2 echo "No file specified"
  exit 1
fi

if [ ".${SRC##*.}" != $TEX_EXT ]; then
  >&2 echo "The file is not a texfile"
  exit 1
fi

load_config "$PATH_CONFIG"

PLAINTEX_FILE=$(create_file "plaintext")
MATCHER_FILE=$(create_file "match_plaintex_input")
ERRORED_FILE=$(create_file "errored_input")

cd "$(dirname "$SRC")" || exit 1
tex_parser_opendetex "$(basename "$SRC")" "$PLAINTEX_FILE" "$MATCHER_FILE"
cd ~- || return

if [ "${CONFIG[SPELLCHECK]}" == "LANGUAGETOOLS" ];then
  if [ "$VERBOSITY" -eq 2 ]; then
    echo "Try pinging LangugateTool servers... it may takes times"
  fi

  if ping -c1 "${CONFIG[HOST]}" > /dev/null; then
    if [ "$VERBOSITY" -eq 2 ]; then
      echo "Server is there !"
      echo "Try test request on the LangugateTool servers..."
    fi
    RESPONSE=$(curl -s http://"${CONFIG[HOST]}":"${CONFIG[PORT]}")
    GOOD_RESPONSE="Error: Missing arguments for LanguageTool API. Please see https://languagetool.org/http-api/swagger-ui/#/default"
   
    if [ "$RESPONSE" != "$GOOD_RESPONSE" ];then
      >&2 echo "Error: LanguageTool server did not response to test request"
      exit 1
    else
      if [ "$VERBOSITY" -eq 2 ]; then
        echo "Languagetool server is up and running"
      fi
       spell_checker_languagetool "$PLAINTEX_FILE" "$ERRORED_FILE"
    fi
    
  else
    >&2 echo "Error: Could not ping the LanguageTool servers at ${CONFIG[HOST]}"
    exit 1
  fi
elif [ "${CONFIG[SPELLCHECK]}" == "HUNSPELL" ];then
  spell_checker_hunspell "$PLAINTEX_FILE" "$ERRORED_FILE"
else
  echo "The spell checker \"${CONFIG[SPELLCHECK]}\" is unknown" 
fi

aggregator_sdtout "$ERRORED_FILE" "$MATCHER_FILE" "$PLAINTEX_FILE"


exit 0
# After is just old

# Cleaning diff files
if [ $CLEAN -eq 1 ]; then
  if [ $SRCISFILE -eq 1 ]; then
    if [ -f "${SRC}${DIFF_EXT}" ]; then
      rm "${SRC}${DIFF_EXT}"
    fi
  else
    find_files "$SRC" $DIFF_EXT $CHECK_HIDDEN | remove_files 
  fi
fi


######################
# Create/Update Dict #
######################
if [ $MAKE_DICT -eq 1 ]; then
  create_dict "$LIST_DICT"
fi


# Typechecking
if [ $SPELL -eq 1 ]; then
  # Generate diff files
  
  EMPTY_FILES=0
  ERRORS=0
  UNKNOWN_WORDS=0
  UNCHANGED_FILES=0
  L_ERRORS=0
  L_UNKNOWN_WORDS=0
  if [ $REPORT -eq 1 ]; then 
    {
      echo "Start " "$(date)"
      echo ""
    } > $REPORT_FILE
  fi
    
  FILES=$(find_files "$SRC" $TEX_EXT $CHECK_HIDDEN $ignore)
  
  mapfile -t array FILES_LIST < <(echo "$FILES" | sed "s/ /\n/g")
  N_FILES=${#FILES_LIST[@]}
  
  if [ "$VERBOSITY" -ge 1 ]; then
    echo "Processing ${N_FILES} file(s)..."
  fi

  for FILE in "${FILES_LIST[@]}"; do
    # Create a reporting for each file
    echo ""
    echo "Processing $FILE"
    OUTPUT=$(report_file "$FILE")
    TMP_FILE_DIFF=$(echo "$OUTPUT" | cut -f1 -d" ")
    TMP_FILE_STDOUT=$(echo "$OUTPUT" | cut -f2 -d" ")
    L_ERRORS=$(echo "$OUTPUT" | cut -f3 -d" ")
    L_UNKNOWN_WORDS=$(echo "$OUTPUT" | cut -f4 -d" ")

    if [[ ONLY_MODIFIED -eq 1 ]]; then
      if [[ -f "$FILE$DIFF_EXT" ]]; then
        if [ "$(wc -l "$TMP_FILE_DIFF" | awk '{ print $1 }')" -ne 0 ]; then
          OLD_SHASUM=$(ith_line_file "$FILE"$DIFF_EXT 5 | cut -f2 -d" ")
          NEW_SHASUM=$(ith_line_file "$TMP_FILE_DIFF" 5 | cut -f2 -d" ")
          if [[ $OLD_SHASUM == "$NEW_SHASUM" ]]; then
            echo "$FILE is unchanged and contains errors"
            UNCHANGED_FILES=$((UNCHANGED_FILES + 1))
            if [ $REPORT -eq 1 ]; then
              echo "$FILE is unchanged" >> $REPORT_FILE
            fi
          else
            cat "$TMP_FILE_STDOUT"
            cat "$TMP_FILE_DIFF" > "$FILE"$DIFF_EXT
            ERRORS=$((ERRORS + L_ERRORS))
            UNKNOWN_WORDS=$((UNKNOWN_WORDS + L_UNKNOWN_WORDS))
            if [ $REPORT -eq 1 ]; then
              echo "$FILE  Errors: $L_ERRORS | Unknown words: $L_UNKNOWN_WORDS" >> $REPORT_FILE
            fi
          fi
        else
          cat "$TMP_FILE_STDOUT"
          EMPTY_FILES=$((EMPTY_FILES + 1))
          if [ $REPORT -eq 1 ]; then
            echo "$FILE is without errors" >> $REPORT_FILE
          fi
        fi
      else 
        if [ "$(wc -l "$TMP_FILE_DIFF" | awk '{ print $1 }')" -ne 0 ]; then
          cat "$TMP_FILE_STDOUT"
          cat "$TMP_FILE_DIFF" > "$FILE"$DIFF_EXT
          ERRORS=$((ERRORS + L_ERRORS))
          UNKNOWN_WORDS=$((UNKNOWN_WORDS + L_UNKNOWN_WORDS))
          if [ $REPORT -eq 1 ]; then
            echo "$FILE  Errors: $L_ERRORS | Unknown words: $L_UNKNOWN_WORDS" >> $REPORT_FILE
          fi
        else
          echo "$FILE$TEX_EXT is unchanged and without errors"
          UNCHANGED_FILES=$((UNCHANGED_FILES + 1))
          if [ $REPORT -eq 1 ]; then
            echo "$FILE is unchanged" >> $REPORT_FILE
          fi
        fi
      fi
    else
      cat "$TMP_FILE_STDOUT"
      if [ "$(wc -l "$TMP_FILE_DIFF" | awk '{ print $1 }')" -ne 0 ]; then
        cat "$TMP_FILE_DIFF" > "$FILE"$DIFF_EXT
        ERRORS=$((ERRORS + L_ERRORS))
        UNKNOWN_WORDS=$((UNKNOWN_WORDS + L_UNKNOWN_WORDS))
        if [ $REPORT -eq 1 ]; then
          echo "$FILE  Errors: $L_ERRORS | Unknown words: $L_UNKNOWN_WORDS" >> $REPORT_FILE
        fi
      else
        EMPTY_FILES=$((EMPTY_FILES + 1))
        if [ $REPORT -eq 1 ]; then
          echo "$FILE is without errors" >> $REPORT_FILE
        fi
      fi
    fi
  done

  if [ $REPORT -eq 1 ]; then
    # Reporting summary of results in a file
    sed -i "1 aEnd    $(date)"  $REPORT_FILE
    {
      echo ""
      echo "# of files with error(s): " $((N_FILES-EMPTY_FILES-UNCHANGED_FILES))
      echo "# of files without error: " $EMPTY_FILES
      if [ $ONLY_MODIFIED -eq 1 ]; then
        echo "# of unmodified files: " $UNCHANGED_FILES
      fi
      echo "# of error(s): " $ERRORS
      echo "# of unknown words: " $UNKNOWN_WORDS
    } >> "$REPORT_FILE"
    if [ "$VERBOSITY" -ge 1 ]; then
      echo ""
      echo "Report summary:"
      echo ""
      cat $REPORT_FILE
    fi
  fi
fi
